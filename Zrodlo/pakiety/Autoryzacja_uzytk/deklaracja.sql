CREATE OR REPLACE PACKAGE autoryzacja_uzytkownikow
IS
	FUNCTION haszowanie_hasla(haslo VARCHAR2) RETURN VARCHAR2;

	FUNCTION sys_op(wartosc VARCHAR2) RETURN VARCHAR2;

	FUNCTION przegl(wartosc VARCHAR2) RETURN VARCHAR2;

	FUNCTION typ_urzadz(wartosc VARCHAR2) RETURN CHAR;

	PROCEDURE autoryzacja_sesji(
		a_id_urzadz  IN urzadzenia.id_urzadz%TYPE,
		a_token      IN tokeny.token%TYPE,
		o_czy_udany  OUT BOOLEAN
		);

	PROCEDURE odswiez_sesje(
		zapytanie IN JSON_OBJECT_T,
		odpowiedz OUT JSON_OBJECT_T
		);

	PROCEDURE rozbijanie_hasla(
		haslo        IN  hasla.haslo_biezace%TYPE,
		wynik_json   OUT hasla.konf_wariant%TYPE,
		z_wariant1   OUT hasla.haslo_biezace%TYPE,
		z_wariant2   OUT hasla.haslo_biezace%TYPE,
		z_wariant3   OUT hasla.haslo_biezace%TYPE,
		z_wariant4   OUT hasla.haslo_biezace%TYPE,
		z_wariant5   OUT hasla.haslo_biezace%TYPE
		);

	PROCEDURE rejestracja_uzytkownika(
		zapytanie IN JSON_OBJECT_T,
		odpowiedz OUT JSON_OBJECT_T
		);

	PROCEDURE logowanie1etap(
		zapytanie IN JSON_OBJECT_T,
		odpowiedz OUT JSON_OBJECT_T
		);

	PROCEDURE logowanie2etap(
		zapytanie IN JSON_OBJECT_T,
		odpowiedz OUT JSON_OBJECT_T
		);

	PROCEDURE zaufaj_urzadz(
		zapytanie IN JSON_OBJECT_T,
		odpowiedz OUT JSON_OBJECT_T
		);

	PROCEDURE zmiana_hasla(
		zapytanie IN JSON_OBJECT_T,
		odpowiedz OUT JSON_OBJECT_T
		);

END autoryzacja_uzytkownikow;