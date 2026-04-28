import calendar
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from django.utils import timezone
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
