CREATE OR REPLACE PACKAGE BODY menu_dynamiczne
IS
	PROCEDURE gen_menu(
		zapytanie IN JSON_OBJECT_T,
		odpowiedz OUT JSON_OBJECT_T
	)
	IS
		CURSOR menu_publiczne IS
			SELECT id, nazwa_kat
				FROM kategorie_menu
				WHERE typ = 'p';
		CURSOR menu_dedykowane(k_id kategorie_menu.id_uzytkownika%TYPE) IS
			SELECT id, nazwa_kat
				FROM kategorie_menu
				WHERE typ = 'p' OR (typ = 'd' AND id_uzytkownika = k_id);
		CURSOR pozycje_kat(k_id_kat pozycje_menu.id_kat%TYPE) IS SELECT typ, nazwa_poz, wartosc FROM pozycje_menu WHERE id_kat = k_id_kat;
		ob_kat JSON_OBJECT_T;
		tab_kat JSON_ARRAY_T;
		tab_poz JSON_ARRAY_T;
		ob_poz JSON_OBJECT_T;
		z_id uzytkownicy.id%TYPE;
		z_n_id NUMBER(1);
		z_id_kat kategorie_menu.id%TYPE;
	BEGIN
		odpowiedz := JSON_OBJECT_T();
		tab_kat := JSON_ARRAY_T();
		IF zapytanie.has('a_id') THEN
			z_id := zapytanie.get_number('a_id');
			FOR petla_kat IN menu_dedykowane(z_id) LOOP
				ob_kat := JSON_OBJECT_T();
				ob_kat.put('nazwa_kat', petla_kat.nazwa_kat);
				tab_poz := JSON_ARRAY_T();
				z_id_kat := petla_kat.id;
				FOR petla_poz IN pozycje_kat(z_id_kat) LOOP
					ob_poz := JSON_OBJECT_T();
					ob_poz.put('typ', petla_poz.typ);
					ob_poz.put('nazwa_poz', petla_poz.nazwa_poz);
					ob_poz.put('wartosc', petla_poz.wartosc);
					tab_poz.append(ob_poz);
				END LOOP;
				ob_kat.put('tab_pozyzcji', tab_poz);	
				tab_kat.append(ob_kat);
			END LOOP;
		ELSE
			FOR petla_kat IN menu_publiczne LOOP
				ob_kat := JSON_OBJECT_T();
				ob_kat.put('nazwa_kat', petla_kat.nazwa_kat);
				tab_poz := JSON_ARRAY_T();
				z_id_kat := petla_kat.id;
				FOR petla_poz IN pozycje_kat(z_id_kat) LOOP
					ob_poz := JSON_OBJECT_T();
					ob_poz.put('typ', petla_poz.typ);
					ob_poz.put('nazwa_poz', petla_poz.nazwa_poz);
					ob_poz.put('wartosc', petla_poz.wartosc);
					tab_poz.append(ob_poz);
				END LOOP;
				ob_kat.put('tab_pozyzcji', tab_poz);
				tab_kat.append(ob_kat);
			END LOOP;
		END IF;
	odpowiedz.put('menu', tab_kat);
	EXCEPTION
		WHEN others THEN
		odpowiedz.put('o_komunikat', 'Błąd krytyczny bazy danych.');
	END gen_menu;

END menu_dynamiczne;