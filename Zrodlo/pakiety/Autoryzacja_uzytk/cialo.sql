CREATE OR REPLACE PACKAGE BODY autoryzacja_uzytkownikow
IS
	FUNCTION haszowanie_hasla(haslo VARCHAR2) RETURN VARCHAR2 IS
		sol VARCHAR2(6 CHAR)    := 'JSJyI.';
		pieprz VARCHAR2(6 CHAR) := '.45SKi';
	BEGIN
		RETURN sol || (dbms_crypto.hash (utl_i18n.string_to_raw (haslo, 'AL32UTF8'), dbms_crypto.hash_sh512)) || pieprz;
	END haszowanie_hasla;

	FUNCTION sys_op(wartosc VARCHAR2) RETURN VARCHAR2 IS
		TYPE tablica_typu_urzadzenia IS TABLE OF VARCHAR2(100 CHAR) INDEX BY VARCHAR2(100 CHAR);
		tablica tablica_typu_urzadzenia;
	    indeks  VARCHAR2(300 CHAR);
		wynik   VARCHAR2(300 CHAR) := 'System nieznany';
	BEGIN
		tablica('windows NT 10.0') := 'Windows 10/11';
		tablica('windows NT 6.3')  := 'Windows 8.1';
	    tablica('windows nt 6.2')  := 'Windows 8';
	    tablica('windows nt 6.1')  := 'Windows 7';
	    tablica('macintosh')       := 'Mac OS X';
	    tablica('mac_powerpc')     := 'Mac OS 9';
	    tablica('linux')           := 'Linux';
	    tablica('ubuntu')          := 'Ubuntu';
	    tablica('iphone')          := 'iPhone';
	    tablica('ipod')            := 'iPod';
	    tablica('ipad')            := 'iPad';
	    tablica('android')         := 'Android';
	    tablica('webos')           := 'Mobile';
	    indeks := tablica.FIRST;
	    WHILE (indeks IS NOT NULL) LOOP
	            IF regexp_count(lower(wartosc), lower(indeks)) > 0 THEN
				    wynik := tablica(indeks);
			    END IF;
	        indeks := tablica.NEXT(indeks);
	    END LOOP;
	    RETURN wynik;
	END sys_op;

	FUNCTION przegl(wartosc VARCHAR2) RETURN VARCHAR2 IS
		TYPE tablica_typu_urzadzenia IS TABLE OF VARCHAR2(100 CHAR) INDEX BY VARCHAR2(100 CHAR);
		tablica tablica_typu_urzadzenia;
	   indeks  VARCHAR2(300 CHAR);
		wynik   VARCHAR2(300 CHAR);
	BEGIN
	    wynik := wartosc;
	    tablica('safari')         := 'Safari';
	    tablica('postmanruntime') := 'PostMan';
		tablica('msie')           := 'Internet Explorer';
		tablica('firefox')        := 'Firefox';
	    tablica('chrome')         := 'Chrome';
	    tablica('edge')           := 'Edge';
	    tablica('opera')          := 'Opera';
	    IF regexp_count(lower(wartosc), 'safari') > 0 THEN
	        wynik := 'Safari';
	        tablica.delete('safari');
	        indeks := tablica.FIRST;
	        WHILE (indeks IS NOT NULL) LOOP
	           IF regexp_count(lower(wartosc), lower(indeks)) > 0 THEN
	               wynik := tablica(indeks);
	           END IF;
	           indeks := tablica.NEXT(indeks);
			END LOOP;
	    ELSIF regexp_count(lower(wartosc), 'postmanruntime') > 0 THEN
        wynik := 'PostMan';
	    END IF; 
	    RETURN wynik;
	END przegl;

	FUNCTION typ_urzadz(wartosc VARCHAR2) RETURN CHAR IS
		TYPE tablica_typu_urzadzenia IS TABLE OF CHAR(1 CHAR) INDEX BY VARCHAR2(100 CHAR);
		tablica tablica_typu_urzadzenia;
	    indeks  VARCHAR2(300 CHAR);
		wynik   CHAR(1 CHAR) := 'i';
	BEGIN
		tablica('windows NT 10.0') := 'k';
		tablica('windows NT 6.3')  := 'k';
	    tablica('windows nt 6.2')  := 'k';
	    tablica('windows nt 6.1')  := 'k';
	    tablica('macintosh')       := 'k';
	    tablica('mac_powerpc')     := 'k';
	    tablica('linux')           := 'k';
	    tablica('ubuntu')          := 'k';
	    tablica('iphone')          := 'm';
	    tablica('ipod')            := 'm';
	    tablica('ipad')            := 'm';
	    tablica('android')         := 'm';
	    tablica('webos')           := 'g';
	    indeks := tablica.FIRST;
	    WHILE (indeks IS NOT NULL) LOOP
	            IF regexp_count(lower(wartosc), lower(indeks)) > 0 THEN
				    wynik := tablica(indeks);
			    END IF;
	        indeks := tablica.NEXT(indeks);
	    END LOOP;
	    RETURN wynik;
	END typ_urzadz;

	PROCEDURE autoryzacja_sesji(
		a_id_urzadz  IN urzadzenia.id_urzadz%TYPE,
		a_token      IN tokeny.token%TYPE,
		o_czy_udany  OUT BOOLEAN
		)
	IS
		n_wierszy_u NUMBER(1);
		n_wierszy_t NUMBER(1);
		z_token     tokeny.token%TYPE;
	BEGIN
		SAVEPOINT ba;
		o_czy_udany := FALSE;
		DELETE FROM tokeny WHERE CURRENT_TIMESTAMP > czas_sesji;
		SELECT count(id_urzadz) INTO n_wierszy_u FROM urzadzenia WHERE id_urzadz = a_id_urzadz AND kategoria = 'z';
		SELECT count(token) INTO n_wierszy_t FROM tokeny WHERE token = a_token;
		IF n_wierszy_u = 1 THEN
			z_token := substr(dbms_random.string('A', dbms_random.value(31, 31)), 0, 31);
			DELETE FROM tokeny WHERE id_urzadz = a_id_urzadz;
			INSERT INTO tokeny (
				id_urzadz,
				token,
				czas_sesji
			) VALUES (
				a_id_urzadz,
				z_token,
				current_timestamp + interval '20' minute);
			o_czy_udany := TRUE;
		ELSIF n_wierszy_t = 1 THEN
			UPDATE tokeny SET czas_sesji = current_timestamp + interval '20' minute WHERE token = a_token;
			o_czy_udany := TRUE;
		ELSE
			DELETE FROM tokeny WHERE id_urzadz = a_id_urzadz;
		END IF;
		COMMIT;
	EXCEPTION
		WHEN others THEN
		ROLLBACK TO ba;
	END autoryzacja_sesji;

	PROCEDURE odswiez_sesje(
		zapytanie IN JSON_OBJECT_T,
		odpowiedz OUT JSON_OBJECT_T
		)
	IS
		z_czy_udany BOOLEAN;
	BEGIN
		odpowiedz := JSON_OBJECT_T();
		IF 	zapytanie.has('a_token') AND
			zapytanie.has('a_id_urzadz') THEN
			autoryzacja_uzytkownikow.autoryzacja_sesji(
			a_id_urzadz  => zapytanie.get_string('a_id_urzadz'),
			a_token      => zapytanie.get_string('a_token'),
			o_czy_udany  => z_czy_udany
			);
			IF z_czy_udany THEN
				odpowiedz.put('o_czy_udany', TRUE);
			ELSE
				odpowiedz.put('o_czy_udany', FALSE);
				odpowiedz.put('o_komunikat', 'Sesja już wygasła.');
			END IF;
		ELSE
			odpowiedz.put('o_komunikat', 'Przesłano błędną hurtownie JSON, lub nie podano wszystkich wymaganych argumentów.');
			odpowiedz.put('o_czy_udany', FALSE);
		END IF;
	EXCEPTION
		WHEN others THEN
		odpowiedz.put('o_komunikat', 'Błąd krytyczny bazy danych.');
		odpowiedz.put('o_czy_udany', FALSE);
	END odswiez_sesje;

	PROCEDURE rozbijanie_hasla(
		haslo        IN  hasla.haslo_biezace%TYPE,
		wynik_json   OUT hasla.konf_wariant%TYPE,
		z_wariant1   OUT hasla.haslo_biezace%TYPE,
		z_wariant2   OUT hasla.haslo_biezace%TYPE,
		z_wariant3   OUT hasla.haslo_biezace%TYPE,
		z_wariant4   OUT hasla.haslo_biezace%TYPE,
		z_wariant5   OUT hasla.haslo_biezace%TYPE
	)
	IS
		wariant_hasla hasla.haslo_biezace%TYPE;
		z_wynik_json  json_object_t;
		tablica_json  json_array_t;
		dlugosc_hasla NUMBER(5);
	BEGIN
		dlugosc_hasla := length(haslo);
		z_wynik_json := json_object_t();
		z_wynik_json.put('dlugosc_hasla', dlugosc_hasla);
		FOR a IN 1..5 LOOP
			wariant_hasla := NULL;
			tablica_json := NULL;
			tablica_json := json_array_t();    
			FOR b IN 1..dlugosc_hasla LOOP
				IF round(dbms_random.value(0, 1), 0) = 1 THEN
	          		wariant_hasla := wariant_hasla || substr(haslo, b, 1);
					tablica_json.append(b);
				END IF;
			END LOOP;
			z_wynik_json.put('wariant' || a, json_array_t(tablica_json));
			CASE
			WHEN a=1 THEN z_wariant1 := wariant_hasla;
			WHEN a=2 THEN z_wariant2 := wariant_hasla;
			WHEN a=3 THEN z_wariant3 := wariant_hasla;
			WHEN a=4 THEN z_wariant4 := wariant_hasla;
		WHEN a=5 THEN z_wariant5 := wariant_hasla;
		END CASE;
		END LOOP;
		wynik_json := z_wynik_json.stringify;
	END rozbijanie_hasla;
	
	PROCEDURE rejestracja_uzytkownika(
		zapytanie IN JSON_OBJECT_T,
		odpowiedz OUT JSON_OBJECT_T
	)
	IS
		n_wierszy           NUMBER(1);
		z_id                uzytkownicy.id%TYPE;
		z_id_urzadz         urzadzenia.id_urzadz%TYPE;
		z_token             tokeny.token%TYPE;
		z_login_mail        uzytkownicy.login_mail%TYPE;
		z_plec              uzytkownicy.plec%TYPE;
		z_nazwa_uzytkownika uzytkownicy.nazwa_uzytkownika%TYPE;
		z_numer_tel         nry_tel.numer_tel%TYPE;
		z_haslo             hasla.haslo_biezace%TYPE;
		z_konf_wariant      hasla.konf_wariant%TYPE;
		z_wariant1          hasla.wariant1%TYPE;
		z_wariant2          hasla.wariant2%TYPE;
		z_wariant3          hasla.wariant3%TYPE;
		z_wariant4          hasla.wariant4%TYPE;
		z_wariant5          hasla.wariant5%TYPE;
		z_ip                logi_uzytk.ip%TYPE;
		z_agent_klienta     logi_uzytk.agent_klienta%TYPE;
		z_sys_op            logi_uzytk.agent_klienta%TYPE;
		z_przegl            logi_uzytk.agent_klienta%TYPE;
	BEGIN
		SAVEPOINT ac;
		odpowiedz := JSON_OBJECT_T();
		IF zapytanie.has('a_login_mail') AND
		   zapytanie.has('a_haslo') AND
		   zapytanie.has('a_powtorzone_haslo') AND
		   zapytanie.has('a_plec') AND
		   zapytanie.has('a_nazwa_uzytkownika') AND
		   zapytanie.has('a_ip') AND 
		   zapytanie.has('a_agent_klienta') THEN
			z_login_mail        := lower(zapytanie.get_string('a_login_mail'));
			z_haslo             := zapytanie.get_string('a_haslo');
			z_plec              := zapytanie.get_string('a_plec');
			z_nazwa_uzytkownika := zapytanie.get_string('a_nazwa_uzytkownika');
			z_ip                := zapytanie.get_string('a_ip');
			z_agent_klienta     := zapytanie.get_string('a_agent_klienta');
			z_sys_op            := autoryzacja_uzytkownikow.sys_op(z_agent_klienta);
			z_przegl            := autoryzacja_uzytkownikow.przegl(z_agent_klienta);
			IF (instr(z_login_mail, '@') != 0) AND (instr(z_login_mail, '.') != 0) THEN
				SELECT count(login_mail) INTO n_wierszy FROM uzytkownicy WHERE login_mail = z_login_mail;
				IF n_wierszy = 1 THEN					
					odpowiedz.put('o_czy_udany', FALSE);
					odpowiedz.put('o_komunikat', 'Login o adresie e-mail '||upper(z_login_mail)||', jest już zarejestrowany.');
				ELSE
					IF z_haslo = zapytanie.get_string('a_powtorzone_haslo') THEN
						IF (length(z_haslo) > 8) AND (length(z_haslo) < 1000) THEN
							INSERT INTO uzytkownicy (
								login_mail,
								nazwa_uzytkownika,
								plec
							) VALUES (
								z_login_mail,
								z_nazwa_uzytkownika,
								z_plec
							);
							SELECT id,
								substr(dbms_random.string('A', dbms_random.value(6, 6)), 0, 6),
								substr(dbms_random.string('A', dbms_random.value(31, 31)), 0, 31)
							INTO z_id,
								 z_id_urzadz,
								 z_token
							FROM uzytkownicy
							WHERE login_mail = z_login_mail;
							autoryzacja_uzytkownikow.rozbijanie_hasla(
								haslo      => z_haslo,
								wynik_json => z_konf_wariant,
								z_wariant1 => z_wariant1,
								z_wariant2 => z_wariant2,
								z_wariant3 => z_wariant3,
								z_wariant4 => z_wariant4,
								z_wariant5 => z_wariant5);
							INSERT INTO hasla (
								id_uzytkownika,
								konf_wariant,
								haslo_biezace,
								haslo_stare,
								wariant1,
								wariant2,
								wariant3,
								wariant4,
								wariant5
							) VALUES (
								z_id,
								z_konf_wariant,
								autoryzacja_uzytkownikow.haszowanie_hasla(z_haslo),
								autoryzacja_uzytkownikow.haszowanie_hasla(z_haslo),
								autoryzacja_uzytkownikow.haszowanie_hasla(z_wariant1),
								autoryzacja_uzytkownikow.haszowanie_hasla(z_wariant2),
								autoryzacja_uzytkownikow.haszowanie_hasla(z_wariant3),
								autoryzacja_uzytkownikow.haszowanie_hasla(z_wariant4),
								autoryzacja_uzytkownikow.haszowanie_hasla(z_wariant5));
							INSERT INTO urzadzenia (
								id_uzytkownika,
								id_urzadz,
								typ
							) VALUES (
								z_id,
								z_id_urzadz,
								autoryzacja_uzytkownikow.typ_urzadz(z_agent_klienta)
							);
							INSERT INTO logi_uzytk(
								id_urzadz,
								ip,
								agent_klienta,
								status
							) VALUES (
								z_id_urzadz,
								z_ip,
								z_agent_klienta,
								'u');
							INSERT INTO tokeny (
								id_urzadz,
								token,
								czas_sesji
							) VALUES (
								z_id_urzadz,
								z_token,
								current_timestamp + interval '20' minute);
							IF zapytanie.has('a_numer_tel') THEN
								z_numer_tel := zapytanie.get_string('a_numer_tel');
								SELECT count(numer_tel) INTO n_wierszy FROM nry_tel WHERE numer_tel = z_numer_tel;
								IF length(z_numer_tel) > 5 AND
									1 > n_wierszy THEN
									INSERT INTO nry_tel(
										id_uzytkownika,
										numer_tel
									) VALUES (
										z_id,
										z_numer_tel
									);
								END IF;								
							END IF;
							odpowiedz.put('o_czy_udany', TRUE);
							odpowiedz.put('o_id', z_id);
							odpowiedz.put('o_id_urzadz', z_id_urzadz);
							odpowiedz.put('o_token', z_token);
							odpowiedz.put('o_komunikat', 'Zostało pomyślnie utworzone konto o loginie '||upper(z_login_mail)||' ! Jeśli chcesz, dodaj te urządzenie do zaufanych.');
							odpowiedz.put('o_ip', z_ip);
							odpowiedz.put('o_sys_op', z_sys_op);
							odpowiedz.put('o_przegl', z_przegl);
						ELSE
							odpowiedz.put('o_czy_udany', FALSE);
							odpowiedz.put('o_komunikat', 'Hasło nie może być krótrze niż osiem znaków. Ani nie może być dłuższe nić 1 000 znaków!');
						END IF;
					ELSE
						odpowiedz.put('o_czy_udany', FALSE);
						odpowiedz.put('o_komunikat', 'Hasła nie są takie same.');
					END IF;


				END IF;
			ELSE
				odpowiedz.put('o_czy_udany', FALSE);
				odpowiedz.put('o_komunikat', 'To nie jest prawidłowy adres e-mail.');
			END IF;
		ELSE
			odpowiedz.put('o_czy_udany', FALSE);
			odpowiedz.put('o_komunikat', 'Przesłano błędną hurtownie JSON, lub nie podano wszystkich wymaganych argumentów.');

		END IF;
		COMMIT;
	EXCEPTION
		WHEN others THEN
		ROLLBACK TO ac;
		odpowiedz.put('o_czy_udany', FALSE);
		odpowiedz.put('o_komunikat', 'Błąd krytyczny bazy danych.');
	END rejestracja_uzytkownika;

	PROCEDURE logowanie1etap(
		zapytanie IN JSON_OBJECT_T,
		odpowiedz OUT JSON_OBJECT_T
		)
	IS
		z_login_mail      uzytkownicy.login_mail%TYPE;
		z_numer_tel       nry_tel.numer_tel%TYPE;
		z_id              uzytkownicy.id%TYPE;
		z_i_prob          uzytkownicy.i_prob%TYPE;
		z_konf_wariant    hasla.konf_wariant%TYPE;
		czy_udany         NUMBER(1);
		wariant           NUMBER(1);
		dlugosc_hasla     NUMBER(3);
		json_konf_wariant JSON_OBJECT_T;
		tablica_elementow JSON_ARRAY_T;
	BEGIN
		odpowiedz := JSON_OBJECT_T();
		IF zapytanie.has('a_login') THEN
			z_login_mail := replace(lower(zapytanie.get_string('a_login')), ' ');
			z_numer_tel := replace(zapytanie.get_string('a_login'), ' ');
			IF (instr(z_login_mail, '@') != 0) AND (instr(z_login_mail, '.') != 0) THEN
				SELECT count(id) INTO czy_udany FROM uzytkownicy WHERE login_mail = z_login_mail;
				IF czy_udany = 1 THEN
					SELECT id INTO z_id FROM uzytkownicy WHERE login_mail = z_login_mail;
					SELECT i_prob INTO z_i_prob FROM uzytkownicy WHERE id = z_id;
					odpowiedz.put('o_czy_udany', TRUE);
				ELSE
					odpowiedz.put('o_czy_udany', FALSE);
					odpowiedz.put('o_komunikat', 'Nie znaleziono takiego loginu (adresu e-mail '||upper(z_login_mail)||'). Spróbuj się zarejstrować.');
				END IF;
			ELSE
				SELECT count(id_uzytkownika) INTO czy_udany FROM nry_tel WHERE numer_tel = z_numer_tel;
				IF czy_udany = 1 THEN
					SELECT id_uzytkownika INTO z_id FROM nry_tel WHERE numer_tel = z_numer_tel;
					SELECT i_prob INTO z_i_prob FROM uzytkownicy WHERE id = z_id;
					odpowiedz.put('o_czy_udany', TRUE);
				ELSE
					odpowiedz.put('o_czy_udany', FALSE);
					odpowiedz.put('o_komunikat', 'Nie znaleziono takiego loginu (numeru tel. '||z_numer_tel||'). Spróbuj się zarejstrować.');
				END IF;
			END IF;
		ELSE
			odpowiedz.put('o_czy_udany', FALSE);
			odpowiedz.put('o_komunikat', 'Przesłano błędną hurtownie JSON, lub nie podano wszystkich wymaganych argumentów.');
		END IF;
		IF czy_udany = 1 AND (z_i_prob = 3 OR z_i_prob = 2) THEN
			wariant := round(dbms_random.value(1, 5), 0);
			SELECT konf_wariant INTO z_konf_wariant FROM hasla WHERE id_uzytkownika = z_id;
			json_konf_wariant := JSON_OBJECT_T(z_konf_wariant);
			tablica_elementow := json_konf_wariant.get_array('wariant'||wariant);
			dlugosc_hasla := json_konf_wariant.get_number('dlugosc_hasla');
			odpowiedz.put('o_id', z_id);
			odpowiedz.put('o_dlugosc_hasla', dlugosc_hasla);
			odpowiedz.put('o_i_prob', z_i_prob);
			odpowiedz.put('o_wariant', wariant);
			odpowiedz.put('o_tablica_elementow', tablica_elementow);
		ELSIF czy_udany = 1 AND z_i_prob = 1 THEN
			odpowiedz.put('o_id', z_id);
			odpowiedz.put('o_i_prob', z_i_prob);
		ELSIF czy_udany = 1 AND z_i_prob < 1 THEN
			odpowiedz.put('o_czy_udany', FALSE);
			odpowiedz.put('o_komunikat', 'Przekroczono ilość nieudanych prób zalogowania się. Skontaktuj się z administratorem!');
		END IF;
	EXCEPTION
		WHEN others THEN
		odpowiedz.put('o_czy_udany', FALSE);
		odpowiedz.put('o_komunikat', 'Błąd krytyczny bazy danych.');
	END logowanie1etap;

	PROCEDURE logowanie2etap(
		zapytanie IN JSON_OBJECT_T,
		odpowiedz OUT JSON_OBJECT_T
		)
	IS
		z_id                uzytkownicy.id%TYPE;
        z_id_urzadz         urzadzenia.id_urzadz%TYPE;
		z_i_prob            uzytkownicy.i_prob%TYPE;
		z_n_id              NUMBER(1);
		wariant             NUMBER(1);
		z_podane_haslo      hasla.haslo_biezace%TYPE;
		z_haslo_biezace     hasla.haslo_biezace%TYPE;
		z_haslo_stare       hasla.haslo_stare%TYPE;
		z_token             tokeny.token%TYPE;
		z_plec              uzytkownicy.plec%TYPE;
		z_nazwa_uzytkownika uzytkownicy.nazwa_uzytkownika%TYPE;
		z_ip                logi_uzytk.ip%TYPE;
		z_agent_klienta     logi_uzytk.agent_klienta%TYPE;
		z_sys_op            logi_uzytk.agent_klienta%TYPE;
		z_przegl            logi_uzytk.agent_klienta%TYPE;
		z_typ_urzadz        urzadzenia.typ%TYPE;
		tablica_logow_u     JSON_ARRAY_T;
		tablica_logow_n     JSON_ARRAY_T;
		json_log            JSON_OBJECT_T;
		CURSOR
		logi_u(k_id uzytkownicy.id%TYPE) IS SELECT
		    ur.id_urzadz,
		    CASE ur.typ
		    WHEN 'k' THEN 'Komputer'
		    WHEN 'm' THEN 'Urządzenie mobilne'
		    WHEN 'g' THEN 'Konsola gier'
		    WHEN 'i' THEN 'Urządzenie nieznane'    
		    END AS typ_urzadz,
		    CASE ur.kategoria
		    WHEN 'j' THEN 'Jednorazowe urządzenie'
		    WHEN 'j' THEN 'Zaufane urządzenie'    
		    END AS kat_urzadz,
		    lu.ip,
		    autoryzacja_uzytkownikow.sys_op(lu.agent_klienta) AS sys_op,
		    autoryzacja_uzytkownikow.przegl(lu.agent_klienta) AS przegl,
		    to_char(lu.data_logu, 'DD-MM-YYYY') AS data_logu,
		    to_char(lu.data_logu, 'SS:MI:HH24') AS czas_logu
			FROM urzadzenia ur LEFT JOIN logi_uzytk lu ON ur.id_urzadz = lu.id_urzadz
			WHERE ur.id_uzytkownika = k_id AND lu.status = 'u'
			ORDER BY lu.data_logu DESC;
		CURSOR
		logi_n(k_id uzytkownicy.id%TYPE) IS SELECT
		    ur.id_urzadz,
		    CASE ur.typ
		    WHEN 'k' THEN 'Komputer'
		    WHEN 'm' THEN 'Urządzenie mobilne'
		    WHEN 'g' THEN 'Konsola gier'
		    WHEN 'i' THEN 'Urządzenie nieznane'    
		    END AS typ_urzadz,
		    CASE ur.kategoria
		    WHEN 'j' THEN 'Jednorazowe urządzenie'
		    WHEN 'j' THEN 'Zaufane urządzenie'    
		    END AS kat_urzadz,
		    lu.ip,
		    autoryzacja_uzytkownikow.sys_op(lu.agent_klienta) AS sys_op,
		    autoryzacja_uzytkownikow.przegl(lu.agent_klienta) AS przegl,
		    to_char(lu.data_logu, 'DD-MM-YYYY') AS data_logu,
		    to_char(lu.data_logu, 'SS:MI:HH24') AS czas_logu
			FROM urzadzenia ur LEFT JOIN logi_uzytk lu ON ur.id_urzadz = lu.id_urzadz
			WHERE ur.id_uzytkownika = k_id AND lu.status = 'n'
			ORDER BY lu.data_logu DESC;
	BEGIN
		SAVEPOINT ad;
		odpowiedz := JSON_OBJECT_T();
		IF zapytanie.has('a_id') AND
		   zapytanie.has('a_haslo') AND
		   zapytanie.has('a_ip') AND 
		   zapytanie.has('a_agent_klienta') THEN
		   z_id            := zapytanie.get_number('a_id');
		   z_podane_haslo  := zapytanie.get_string('a_haslo');
		   z_ip            := zapytanie.get_string('a_ip');
		   z_agent_klienta := zapytanie.get_string('a_agent_klienta');
		   z_sys_op        := autoryzacja_uzytkownikow.sys_op(z_agent_klienta);
		   z_przegl        := autoryzacja_uzytkownikow.przegl(z_agent_klienta);
		   z_typ_urzadz    := autoryzacja_uzytkownikow.typ_urzadz(z_agent_klienta);
		   SELECT count(id) INTO z_n_id FROM uzytkownicy WHERE id = z_id;
		   IF z_n_id = 1 THEN
				SELECT plec,
					nazwa_uzytkownika,
					i_prob
				INTO z_plec,
    			    z_nazwa_uzytkownika,
					z_i_prob
				FROM uzytkownicy WHERE id = z_id;
				z_id_urzadz := substr(dbms_random.string('A', dbms_random.value(6, 6)), 0, 6);
				INSERT INTO urzadzenia (
					id_uzytkownika,
					id_urzadz,
					typ
				) VALUES (
					z_id,
					z_id_urzadz,
					z_typ_urzadz
				);
				IF z_i_prob > 0 THEN
					IF (z_i_prob = 3 OR z_i_prob = 2) AND zapytanie.has('a_wariant') THEN
						wariant := zapytanie.get_number('a_wariant');
						CASE wariant						
							WHEN 1 THEN
								SELECT wariant1 INTO z_haslo_biezace FROM hasla WHERE id_uzytkownika = z_id;
							WHEN 2 THEN
								SELECT wariant2 INTO z_haslo_biezace FROM hasla WHERE id_uzytkownika = z_id;
							WHEN 3 THEN
								SELECT wariant3 INTO z_haslo_biezace FROM hasla WHERE id_uzytkownika = z_id;
							WHEN 4 THEN
								SELECT wariant4 INTO z_haslo_biezace FROM hasla WHERE id_uzytkownika = z_id;
							WHEN 5 THEN
								SELECT wariant5 INTO z_haslo_biezace FROM hasla WHERE id_uzytkownika = z_id;
							ELSE
								odpowiedz.put('o_czy_udany', FALSE);
								odpowiedz.put('o_komunikat', 'Błędny wariant hasła!');
						END CASE;
					ELSIF z_i_prob = 1 THEN
						SELECT haslo_biezace, haslo_stare INTO z_haslo_biezace, z_haslo_stare FROM hasla WHERE id_uzytkownika = z_id;
					END IF;
					IF autoryzacja_uzytkownikow.haszowanie_hasla(z_podane_haslo) = z_haslo_biezace THEN
						z_token := substr(dbms_random.string('A', dbms_random.value(31, 31)), 0, 31);
						INSERT INTO logi_uzytk (
							id_urzadz,
							ip,
							agent_klienta,
							status
						) VALUES (
							z_id_urzadz,
							z_ip,
							z_agent_klienta,
							'u');
						INSERT INTO tokeny (
							id_urzadz,
							token,
							czas_sesji
						) VALUES (
							z_id_urzadz,
							z_token,
							current_timestamp + interval '20' minute);
						tablica_logow_u := JSON_ARRAY_T();
						tablica_logow_n := JSON_ARRAY_T();
						FOR petla_logow IN logi_u(z_id) LOOP
							json_log := JSON_OBJECT_T();							
							json_log.put('data_logu', petla_logow.data_logu);
							json_log.put('czas_logu', petla_logow.czas_logu);
							json_log.put('id_urzadz', petla_logow.id_urzadz);
							json_log.put('typ_urzadz', petla_logow.typ_urzadz);
							json_log.put('kat_urzadz', petla_logow.kat_urzadz);
							json_log.put('ip', petla_logow.ip);
							json_log.put('sys_op', petla_logow.sys_op);
							json_log.put('przegl', petla_logow.przegl);
							tablica_logow_u.append(json_log);
						END LOOP;
						FOR petla_logow IN logi_n(z_id) LOOP
							json_log := JSON_OBJECT_T();
							json_log.put('data_logu', petla_logow.data_logu);
							json_log.put('czas_logu', petla_logow.czas_logu);
							json_log.put('id_urzadz', petla_logow.id_urzadz);
							json_log.put('typ_urzadz', petla_logow.typ_urzadz);
							json_log.put('kat_urzadz', petla_logow.kat_urzadz);
							json_log.put('ip', petla_logow.ip);
							json_log.put('sys_op', petla_logow.sys_op);
							json_log.put('przegl', petla_logow.przegl);
							tablica_logow_n.append(json_log);
						END LOOP;
						odpowiedz.put('o_czy_udany', TRUE);
						odpowiedz.put('o_id_urzadz', z_id_urzadz);
						odpowiedz.put('o_token', z_token);
						odpowiedz.put('o_ip', z_ip);
						odpowiedz.put('o_sys_op', z_sys_op);
						odpowiedz.put('o_przegl', z_przegl);
						odpowiedz.put('o_plec', z_plec);
						odpowiedz.put('o_nazwa_uzytkownika', z_nazwa_uzytkownika);
						odpowiedz.put('o_tablica_logow_u', tablica_logow_u);
						odpowiedz.put('o_tablica_logow_n', tablica_logow_n);
					ELSIF autoryzacja_uzytkownikow.haszowanie_hasla(z_podane_haslo) = z_haslo_stare THEN
						INSERT INTO logi_uzytk (
							id_urzadz,
							ip,
							agent_klienta,
							status
						) VALUES (
							z_id_urzadz,
							z_ip,
							z_agent_klienta,
							'n');
						odpowiedz.put('o_czy_udany', FALSE);
						odpowiedz.put('o_komunikat', 'Podano stare / poprzednie hasło.');
					ELSE
						UPDATE uzytkownicy SET i_prob = (z_i_prob - 1) WHERE id = z_id;
						INSERT INTO logi_uzytk (
							id_urzadz,
							ip,
							agent_klienta,
							status
						) VALUES (
							z_id_urzadz,
							z_ip,
							z_agent_klienta,
							'n');
						odpowiedz.put('o_czy_udany', FALSE);
						odpowiedz.put('o_komunikat', 'Podano błędne hasło.');
					END IF;
				ELSE
					odpowiedz.put('o_czy_udany', FALSE);
					odpowiedz.put('o_komunikat', 'Przekroczono ilość nieudanych prób zalogowania się. Skontaktuj się z administratorem!');
				END IF;
		   ELSE
				odpowiedz.put('o_czy_udany', FALSE);
				odpowiedz.put('o_komunikat', 'Błędny identyfikator.');
		   END IF;

		ELSE
			odpowiedz.put('o_czy_udany', FALSE);
			odpowiedz.put('o_komunikat', 'Przesłano błędną hurtownie JSON, lub nie podano wszystkich wymaganych argumentów.');
		END IF;
		COMMIT;
	EXCEPTION
		WHEN others THEN
		ROLLBACK TO ad;
		odpowiedz.put('o_czy_udany', FALSE);
		odpowiedz.put('o_komunikat', 'Błąd krytyczny bazy danych.');
	END logowanie2etap;

	PROCEDURE zaufaj_urzadz(
		zapytanie IN JSON_OBJECT_T,
		odpowiedz OUT JSON_OBJECT_T
		)
	IS
		n_wierszy   NUMBER(1);
		z_id_urzadz urzadzenia.id_urzadz%TYPE;
	BEGIN
		SAVEPOINT bc;
		odpowiedz := JSON_OBJECT_T();
		IF zapytanie.has('a_id_urzadz') THEN
			z_id_urzadz := zapytanie.get_string('a_id_urzadz');
			SELECT count(id_urzadz) INTO n_wierszy FROM urzadzenia WHERE id_urzadz = z_id_urzadz;
			IF n_wierszy = 1 THEN
				UPDATE urzadzenia SET kategoria = 'z' WHERE id_urzadz = z_id_urzadz;
				odpowiedz.put('o_czy_udany', TRUE);
				odpowiedz.put('o_komunikat', 'Pomyślnie dodano urządzenie do zaufanych.');
			ELSE
				odpowiedz.put('o_czy_udany', FALSE);
				odpowiedz.put('o_komunikat', 'Błędny identyfikator urzadzenia.');
			END IF;
		ELSE
			odpowiedz.put('o_czy_udany', FALSE);
			odpowiedz.put('o_komunikat', 'Przesłano błędną hurtownie JSON, lub nie podano wszystkich wymaganych argumentów.');
		END IF;
		COMMIT;
	EXCEPTION
		WHEN others THEN
		ROLLBACK TO bc;
		odpowiedz.put('o_czy_udany', FALSE);
		odpowiedz.put('o_komunikat', 'Błąd krytyczny bazy danych');
	END zaufaj_urzadz;

	PROCEDURE zmiana_hasla(
		zapytanie IN JSON_OBJECT_T,
		odpowiedz OUT JSON_OBJECT_T
		)
	IS
		z_id               uzytkownicy.id%TYPE;
		czy_jest           NUMBER(1);
		z_haslo            hasla.haslo_biezace%TYPE;
		z_nowe_haslo       hasla.haslo_biezace%TYPE;
		z_powtorzone_haslo hasla.haslo_biezace%TYPE;
		z_haslo_biezace    hasla.haslo_biezace%TYPE;
		z_konf_wariant     hasla.konf_wariant%TYPE;
		z_wariant1         hasla.wariant1%TYPE;
		z_wariant2         hasla.wariant2%TYPE;
		z_wariant3         hasla.wariant3%TYPE;
		z_wariant4         hasla.wariant4%TYPE;
		z_wariant5         hasla.wariant5%TYPE;

	BEGIN
		SAVEPOINT bb;
		odpowiedz := JSON_OBJECT_T();
		IF zapytanie.has('a_id') AND
		   zapytanie.has('a_haslo') AND
		   zapytanie.has('a_nowe_haslo') AND
		   zapytanie.has('a_powtorzone_haslo') THEN
		   z_id               := zapytanie.get_number('a_id');
		   SELECT count(id) INTO czy_jest FROM uzytkownicy WHERE id = z_id;
		   z_haslo            := zapytanie.get_string('a_haslo');
		   z_nowe_haslo       := zapytanie.get_string('a_nowe_haslo');
		   z_powtorzone_haslo := zapytanie.get_string('a_powtorzone_haslo');
		   IF czy_jest = 1 THEN
				IF (length(z_nowe_haslo) > 8) AND (length(z_nowe_haslo) < 1000) THEN
					IF z_nowe_haslo = z_powtorzone_haslo THEN
						SELECT haslo_biezace INTO z_haslo_biezace FROM hasla WHERE id_uzytkownika = z_id;
						IF autoryzacja_uzytkownikow.haszowanie_hasla(z_haslo) = z_haslo_biezace THEN
							DELETE FROM hasla WHERE id_uzytkownika = z_id;
							autoryzacja_uzytkownikow.rozbijanie_hasla(
								haslo      => z_nowe_haslo,
								wynik_json => z_konf_wariant,
								z_wariant1 => z_wariant1,
								z_wariant2 => z_wariant2,
								z_wariant3 => z_wariant3,
								z_wariant4 => z_wariant4,
								z_wariant5 => z_wariant5);
							INSERT INTO hasla (
								id_uzytkownika,
								konf_wariant,
								haslo_biezace,
								haslo_stare,
								wariant1,
								wariant2,
								wariant3,
								wariant4,
								wariant5
							) VALUES (
								z_id,
								z_konf_wariant,
								autoryzacja_uzytkownikow.haszowanie_hasla(z_nowe_haslo),
								autoryzacja_uzytkownikow.haszowanie_hasla(z_haslo),
								autoryzacja_uzytkownikow.haszowanie_hasla(z_wariant1),
								autoryzacja_uzytkownikow.haszowanie_hasla(z_wariant2),
								autoryzacja_uzytkownikow.haszowanie_hasla(z_wariant3),
								autoryzacja_uzytkownikow.haszowanie_hasla(z_wariant4),
								autoryzacja_uzytkownikow.haszowanie_hasla(z_wariant5));
							odpowiedz.put('o_czy_udany', TRUE);
							odpowiedz.put('o_komunikat', 'Zmieniono hasło użytkownika na nowe, zawierające '||length(z_nowe_haslo)||' znaków.');
						ELSE
							odpowiedz.put('o_czy_udany', FALSE);
							odpowiedz.put('o_komunikat', 'Podano błędne hasło bieżące.');
						END IF;
					ELSE
						odpowiedz.put('o_czy_udany', FALSE);
						odpowiedz.put('o_komunikat', 'Hasła nie są takie same.');
					END IF;
				ELSE
					odpowiedz.put('o_czy_udany', FALSE);
					odpowiedz.put('o_komunikat', 'Hasło nie może być krótrze niż osiem znaków. Ani nie może być dłuższe nić 1 000 znaków!');
					END IF;
		   ELSE
				odpowiedz.put('o_czy_udany', FALSE);
				odpowiedz.put('o_komunikat', 'Błędny identyfikator.');
		   END IF;
		ELSE
			odpowiedz.put('o_czy_udany', FALSE);
			odpowiedz.put('o_komunikat', 'Przesłano błędną hurtownie JSON, lub nie podano wszystkich wymaganych argumentów.');
		END IF;
		COMMIT;
	EXCEPTION
		WHEN others THEN
		ROLLBACK TO bb;
		odpowiedz.put('o_czy_udany', FALSE);
		odpowiedz.put('o_komunikat', 'Błąd krytyczny bazy danych');
	END zmiana_hasla;
END autoryzacja_uzytkownikow;