from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0008_foodintake_confidence_score_foodintake_weekday_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='userprofile',
            name='activity_frequency',
            field=models.CharField(
                blank=True, default='',
                choices=[('0_1', '0–1 days/week'), ('2_3', '2–3 days/week'),
                         ('4_5', '4–5 days/week'), ('6_7', '6–7 days/week')],
                max_length=10),
        ),
        migrations.AddField(
            model_name='userprofile',
            name='activity_intensity',
            field=models.CharField(
                blank=True, default='',
                choices=[('low', 'Low'), ('moderate', 'Moderate'),
                         ('high', 'High'), ('extreme', 'Extreme')],
                max_length=10),
        ),
        migrations.AddField(
            model_name='userprofile',
            name='activity_duration',
            field=models.CharField(
                blank=True, default='',
                choices=[('under_30', '< 30 min'), ('30_60', '30–60 min'),
                         ('60_90', '60–90 min'), ('over_90', '90+ min')],
                max_length=10),
        ),
        migrations.AddField(
            model_name='userprofile',
            name='activity_types',
            field=models.TextField(blank=True, default=''),
        ),
    ]
