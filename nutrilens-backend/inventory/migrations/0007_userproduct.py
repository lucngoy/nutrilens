from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('inventory', '0006_alter_inventoryitem_image_url_and_more'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='UserProduct',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('barcode', models.CharField(blank=True, default='', max_length=50)),
                ('name', models.CharField(max_length=255)),
                ('brand', models.CharField(blank=True, default='', max_length=255)),
                ('serving_size', models.FloatField(default=100)),
                ('serving_unit', models.CharField(default='g', max_length=20)),
                ('calories', models.FloatField(blank=True, null=True)),
                ('protein', models.FloatField(blank=True, null=True)),
                ('carbohydrates', models.FloatField(blank=True, null=True)),
                ('fat', models.FloatField(blank=True, null=True)),
                ('sugar', models.FloatField(blank=True, null=True)),
                ('salt', models.FloatField(blank=True, null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('user', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE,
                    related_name='user_products', to=settings.AUTH_USER_MODEL)),
            ],
            options={'ordering': ['-created_at']},
        ),
    ]
