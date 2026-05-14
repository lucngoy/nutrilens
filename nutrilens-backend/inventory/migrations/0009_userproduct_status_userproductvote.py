from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('inventory', '0008_userproduct_image'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.AddField(
            model_name='userproduct',
            name='status',
            field=models.CharField(
                choices=[('pending', 'Pending'), ('community_verified', 'Community Verified'),
                         ('approved', 'Approved'), ('rejected', 'Rejected')],
                default='pending', max_length=20),
        ),
        migrations.AddField(
            model_name='userproduct',
            name='confirmation_count',
            field=models.PositiveIntegerField(default=0),
        ),
        migrations.AddField(
            model_name='userproduct',
            name='flag_count',
            field=models.PositiveIntegerField(default=0),
        ),
        migrations.CreateModel(
            name='UserProductVote',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('vote', models.CharField(choices=[('confirm', 'Confirm'), ('flag', 'Flag')], max_length=10)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('product', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE,
                    related_name='votes', to='inventory.userproduct')),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE,
                    related_name='product_votes', to=settings.AUTH_USER_MODEL)),
            ],
            options={'unique_together': {('user', 'product')}},
        ),
    ]
