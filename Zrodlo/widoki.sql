CREATE VIEW w_nry_tel(
login_mail, numer_tel, nazwa_uzytkownika, plec, data_rejestracji)
AS SELECT
uz.login_mail, nt.numer_tel, uz.nazwa_uzytkownika, uz.plec, uz.data_utworzenia
FROM uzytkownicy uz
LEFT JOIN nry_tel nt ON uz.id = nt.id_uzytkownika;