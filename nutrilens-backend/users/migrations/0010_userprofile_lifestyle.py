from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0009_userprofile_activity_scoring'),
    ]

    operations = [
        migrations.AddField(
            model_name='userprofile',
            name='lifestyle',
            field=models.CharField(
                blank=True, default='desk',
                choices=[('desk', 'Desk job'), ('mixed', 'Mixed'), ('physical', 'Physical job')],
                max_length=10),
        ),
    ]
