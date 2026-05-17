from django.contrib import admin
from django.utils.html import format_html
from .models import UserProduct, UserProductVote


@admin.register(UserProduct)
class UserProductAdmin(admin.ModelAdmin):
    list_display = ['name', 'brand', 'user', 'status_badge', 'confirmation_count',
                    'flag_count', 'created_at']
    list_filter = ['status', 'created_at']
    search_fields = ['name', 'brand', 'user__username', 'barcode']
    readonly_fields = ['user', 'barcode', 'confirmation_count', 'flag_count',
                       'created_at', 'updated_at', 'product_image']
    ordering = ['-created_at']

    fieldsets = (
        ('Product', {
            'fields': ('name', 'brand', 'barcode', 'product_image', 'user')
        }),
        ('Nutrition (per serving)', {
            'fields': ('serving_size', 'serving_unit',
                       'calories', 'protein', 'carbohydrates', 'fat', 'sugar', 'salt')
        }),
        ('Moderation', {
            'fields': ('status', 'confirmation_count', 'flag_count',
                       'created_at', 'updated_at')
        }),
    )

    actions = ['approve_products', 'reject_products', 'reset_to_pending']

    @admin.display(description='Status')
    def status_badge(self, obj):
        colors = {
            'pending': '#F39C12',
            'community_verified': '#2980B9',
            'approved': '#27AE60',
            'rejected': '#E74C3C',
        }
        color = colors.get(obj.status, '#999')
        return format_html(
            '<span style="background:{};color:#fff;padding:3px 10px;'
            'border-radius:12px;font-size:11px;font-weight:600">{}</span>',
            color, obj.get_status_display()
        )

    @admin.display(description='Image')
    def product_image(self, obj):
        if obj.image:
            return format_html('<img src="{}" style="max-height:120px;border-radius:8px"/>', obj.image.url)
        return '—'

    @admin.action(description='✅ Approve selected products')
    def approve_products(self, request, queryset):
        updated = queryset.exclude(status='approved').update(status='approved')
        self.message_user(request, f'{updated} product(s) approved.')

    @admin.action(description='❌ Reject selected products')
    def reject_products(self, request, queryset):
        updated = queryset.exclude(status='rejected').update(status='rejected')
        self.message_user(request, f'{updated} product(s) rejected.')

    @admin.action(description='🔄 Reset to Pending')
    def reset_to_pending(self, request, queryset):
        updated = queryset.update(status='pending')
        self.message_user(request, f'{updated} product(s) reset to pending.')


@admin.register(UserProductVote)
class UserProductVoteAdmin(admin.ModelAdmin):
    list_display = ['user', 'product', 'vote', 'created_at']
    list_filter = ['vote']
    search_fields = ['user__username', 'product__name']
