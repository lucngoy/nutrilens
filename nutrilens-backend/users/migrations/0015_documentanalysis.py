from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0014_userprofile_medical_consent'),
    ]

    operations = [
        migrations.CreateModel(
            name='DocumentAnalysis',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('blood_glucose',              models.FloatField(blank=True, null=True)),
                ('hba1c',                      models.FloatField(blank=True, null=True)),
                ('cholesterol_total',          models.FloatField(blank=True, null=True)),
                ('cholesterol_ldl',            models.FloatField(blank=True, null=True)),
                ('cholesterol_hdl',            models.FloatField(blank=True, null=True)),
                ('triglycerides',              models.FloatField(blank=True, null=True)),
                ('blood_pressure_systolic',    models.IntegerField(blank=True, null=True)),
                ('blood_pressure_diastolic',   models.IntegerField(blank=True, null=True)),
                ('vitamin_d',                  models.FloatField(blank=True, null=True)),
                ('vitamin_b12',                models.FloatField(blank=True, null=True)),
                ('ferritin',                   models.FloatField(blank=True, null=True)),
                ('summary',                    models.TextField(blank=True, default='')),
                ('key_findings',               models.JSONField(default=list)),
                ('dietary_recommendations',    models.JSONField(default=list)),
                ('analyzed_at',               models.DateTimeField(auto_now_add=True)),
                ('document', models.OneToOneField(
                    on_delete=django.db.models.deletion.CASCADE,
                    related_name='analysis',
                    to='users.medicaldocument')),
            ],
            options={'ordering': ['-analyzed_at']},
        ),
    ]
