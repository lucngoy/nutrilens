from django.urls import path
from .views import MonthlyBudgetView, SpendingEntryCreateView, SpendingEntryDeleteView, BudgetInsightsView

urlpatterns = [
    path('', MonthlyBudgetView.as_view(), name='budget'),
    path('insights/', BudgetInsightsView.as_view(), name='budget-insights'),
    path('spending/add/', SpendingEntryCreateView.as_view(), name='spending-add'),
    path('spending/<int:pk>/delete/', SpendingEntryDeleteView.as_view(), name='spending-delete'),
]
