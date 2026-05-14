from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('inventory', '0007_userproduct'),
    ]

    operations = [
        migrations.AddField(
            model_name='userproduct',
            name='image',
            field=models.ImageField(blank=True, null=True, upload_to='user_products/'),
        ),
    ]
