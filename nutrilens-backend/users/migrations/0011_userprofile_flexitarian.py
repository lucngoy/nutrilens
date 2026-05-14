from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0010_userprofile_lifestyle'),
    ]

    operations = [
        migrations.AddField(
            model_name='userprofile',
            name='is_flexitarian',
            field=models.BooleanField(default=False),
        ),
    ]
