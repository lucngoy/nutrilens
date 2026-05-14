from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0011_userprofile_flexitarian'),
    ]

    operations = [
        migrations.AddField(
            model_name='userprofile',
            name='diabetes_type',
            field=models.CharField(
                blank=True, default='',
                choices=[('type_1', 'Type 1'), ('type_2', 'Type 2'), ('gestational', 'Gestational')],
                max_length=15),
        ),
        migrations.AddField(
            model_name='userprofile',
            name='lactose_intolerance_level',
            field=models.CharField(
                blank=True, default='',
                choices=[('mild', 'Mild'), ('severe', 'Severe')],
                max_length=10),
        ),
    ]
