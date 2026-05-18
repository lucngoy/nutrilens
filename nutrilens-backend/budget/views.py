import calendar
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.parsers import MultiPartParser, FormParser
from django.utils import timezone
from django.conf import settings
from .models import MonthlyBudget, SpendingEntry
from .serializers import MonthlyBudgetSerializer, SpendingEntrySerializer


class MonthlyBudgetView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        month = request.query_params.get('month', timezone.now().strftime('%Y-%m'))
        try:
            budget = MonthlyBudget.objects.get(user=request.user, month=month)
            return Response(MonthlyBudgetSerializer(budget).data)
        except MonthlyBudget.DoesNotExist:
            return Response(None, status=status.HTTP_204_NO_CONTENT)

    def post(self, request):
        month = request.data.get('month', timezone.now().strftime('%Y-%m'))
        amount = request.data.get('amount')
        if not amount:
            return Response({'error': 'amount is required'}, status=status.HTTP_400_BAD_REQUEST)

        budget, created = MonthlyBudget.objects.update_or_create(
            user=request.user,
            month=month,
            defaults={'amount': amount},
        )
        return Response(
            MonthlyBudgetSerializer(budget).data,
            status=status.HTTP_201_CREATED if created else status.HTTP_200_OK,
        )


class SpendingEntryCreateView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        month = request.data.get('month', timezone.now().strftime('%Y-%m'))
        try:
            budget = MonthlyBudget.objects.get(user=request.user, month=month)
        except MonthlyBudget.DoesNotExist:
            return Response({'error': 'No budget defined for this month'}, status=status.HTTP_404_NOT_FOUND)

        serializer = SpendingEntrySerializer(data=request.data)
        if serializer.is_valid():
            serializer.save(user=request.user, budget=budget)
            updated_budget = MonthlyBudgetSerializer(budget).data
            return Response(updated_budget, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class SpendingEntryDeleteView(generics.DestroyAPIView):
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return SpendingEntry.objects.filter(user=self.request.user)

    def get_object(self):
        try:
            return SpendingEntry.objects.get(id=self.kwargs['pk'], user=self.request.user)
        except SpendingEntry.DoesNotExist:
            from rest_framework.exceptions import NotFound
            raise NotFound()

    def destroy(self, request, *args, **kwargs):
        instance = self.get_object()
        budget = instance.budget
        instance.delete()
        return Response(MonthlyBudgetSerializer(budget).data)


class ReceiptScanView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    _PROMPT = (
        "You are a grocery receipt parser. Extract data from this receipt image and return ONLY valid JSON "
        "with this exact structure (use null for missing values):\n"
        '{"store":null,"purchase_date":null,"total":null,"currency":null,'
        '"lines":[{"description":"...","amount":0.00,"quantity":1}],"raw_text":""}\n'
        "Rules:\n"
        "- purchase_date format: YYYY-MM-DD\n"
        "- amount is per-line price (already multiplied by quantity)\n"
        "- currency is ISO code (EUR, USD, CAD, GBP…)\n"
        "- raw_text is the full receipt text you can read\n"
        "- Expand abbreviations when confident (COK 1.5L → Coca-Cola 1.5L)\n"
        "- If you cannot read the receipt clearly, still return the structure with null values"
    )

    def post(self, request):
        image = request.FILES.get('image')
        if not image:
            return Response({'error': 'image is required'}, status=status.HTTP_400_BAD_REQUEST)

        api_key = getattr(settings, 'GROQ_API_KEY', None)
        if not api_key:
            return Response({'error': 'AI service not configured'}, status=status.HTTP_503_SERVICE_UNAVAILABLE)

        try:
            import base64, json, mimetypes
            from groq import Groq

            mime = image.content_type or 'image/jpeg'
            b64 = base64.b64encode(image.read()).decode()

            client = Groq(api_key=api_key)
            completion = client.chat.completions.create(
                model='meta-llama/llama-4-scout-17b-16e-instruct',
                messages=[{
                    'role': 'user',
                    'content': [
                        {'type': 'image_url', 'image_url': {'url': f'data:{mime};base64,{b64}'}},
                        {'type': 'text', 'text': self._PROMPT},
                    ],
                }],
                max_tokens=1200,
                temperature=0.1,
            )
            raw = completion.choices[0].message.content.strip()
            start = raw.find('{')
            end = raw.rfind('}') + 1
            data = json.loads(raw[start:end]) if start != -1 else {}

            lines = []
            for line in (data.get('lines') or []):
                try:
                    amount = float(line.get('amount') or 0)
                    if amount > 0:
                        lines.append({
                            'description': str(line.get('description') or '').strip()[:255],
                            'amount': round(amount, 2),
                            'quantity': int(line.get('quantity') or 1),
                        })
                except (TypeError, ValueError):
                    continue

            return Response({
                'store': data.get('store'),
                'purchase_date': data.get('purchase_date'),
                'total': data.get('total'),
                'currency': data.get('currency'),
                'lines': lines,
                'raw_text': (data.get('raw_text') or '')[:2000],
            })

        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class ReceiptConfirmView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        lines = request.data.get('lines', [])
        date_str = request.data.get('date')
        month = request.data.get('month', timezone.now().strftime('%Y-%m'))
        store = request.data.get('store', '')

        if not lines:
            return Response({'error': 'lines is required'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            budget = MonthlyBudget.objects.get(user=request.user, month=month)
        except MonthlyBudget.DoesNotExist:
            return Response(
                {'error': 'No budget defined for this month. Set a budget first.'},
                status=status.HTTP_404_NOT_FOUND,
            )

        from datetime import date as date_cls
        try:
            entry_date = date_cls.fromisoformat(date_str) if date_str else timezone.now().date()
        except ValueError:
            entry_date = timezone.now().date()

        created = []
        for line in lines:
            try:
                amount = float(line.get('amount') or 0)
                desc = str(line.get('description') or '').strip()[:255]
                if amount > 0 and desc:
                    entry = SpendingEntry.objects.create(
                        user=request.user,
                        budget=budget,
                        description=desc,
                        amount=round(amount, 2),
                        category='groceries',
                        date=entry_date,
                    )
                    created.append(entry.id)
            except (TypeError, ValueError):
                continue

        return Response({
            'inserted': len(created),
            'budget': MonthlyBudgetSerializer(budget).data,
        }, status=status.HTTP_201_CREATED)


class BudgetInsightsView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        month = request.query_params.get('month', timezone.now().strftime('%Y-%m'))
        try:
            budget = MonthlyBudget.objects.get(user=request.user, month=month)
        except MonthlyBudget.DoesNotExist:
            return Response(None, status=status.HTTP_204_NO_CONTENT)

        pace = budget.pace_status
        projected = budget.projected_spent
        amount = float(budget.amount)

        today = timezone.now().date()
        year, mon = map(int, month.split('-'))
        days_in_month = calendar.monthrange(year, mon)[1]
        days_remaining = max(0, days_in_month - today.day) if (today.year == year and today.month == mon) else 0

        if pace == 'exceeded':
            message = "You've exceeded your budget this month"
        elif pace == 'warning':
            message = f"At this pace, you'll spend ${projected:.0f} — above your ${amount:.0f} budget"
        else:
            message = "You're on track with your budget"

        return Response({
            'status': pace,
            'message': message,
            'projected_spent': projected,
            'budget': amount,
            'daily_budget': budget.daily_budget,
            'avg_daily_spent': budget.avg_daily_spent,
            'days_remaining': days_remaining,
        })
