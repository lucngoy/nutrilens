from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0013_alter_userprofile_goal'),
    ]

    operations = [
        migrations.AddField(
            model_name='userprofile',
            name='medical_consent_accepted',
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name='userprofile',
            name='medical_consent_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
    ]
