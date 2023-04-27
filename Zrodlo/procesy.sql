DECLARE
	z_zapytanie JSON_OBJECT_T;
	z_odpowiedz JSON_OBJECT_T;
BEGIN
	z_zapytanie := JSON_OBJECT_T();
	z_zapytanie.put('a_login_mail', :1_LOGIN_MAIL);
	z_zapytanie.put('a_numer_tel', :1_NUMER_TEL);
	z_zapytanie.put('a_plec', :1_PLEC);
	z_zapytanie.put('a_nazwa_uzytkownika', :1_NAZWA_UZYTK);
	z_zapytanie.put('a_haslo', :1_HASLO);
	z_zapytanie.put('a_powtorzone_haslo', :1_HASLO_POWT);
	z_zapytanie.put('a_ip', owa_util.get_cgi_env('REMOTE_ADDR'));
	z_zapytanie.put('a_agent_klienta', owa_util.get_cgi_env('HTTP_USER_AGENT'));
	autoryzacja_uzytkownikow.rejestracja_uzytkownika(
		zapytanie => z_zapytanie,
		odpowiedz => z_odpowiedz);
	:1_ZAP_JSON := z_zapytanie.stringify;
	:1_ODP_JSON := z_odpowiedz.stringify;
	:1_KOMUNIKAT := z_odpowiedz.get_string('o_komunikat');
END;