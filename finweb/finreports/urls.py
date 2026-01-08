from django.urls import path

from  finreports import views

urlpatterns = [
    # path("", views.IndexView.as_view(), name="index"),
    path("", views.index, name="index"),
    path("balancesheet/", views.balancesheet, name="bs"),
    path("pl/", views.pl, name="pl"),
    path("araging/", views.araging, name="araging"),
    # new JSON endpoints
    path('api/pl/', views.pl_json, name='pl_json'),
    path('api/balance_sheet/', views.balance_sheet_json, name='balance_sheet_json'),
    path('api/ar_aging/', views.araging_json, name='araging_json'),

]