CREATE OR REPLACE PACKAGE menu_dynamiczne
IS
	PROCEDURE gen_menu(
		zapytanie IN JSON_OBJECT_T,
		odpowiedz OUT JSON_OBJECT_T
		);
END menu_dynamiczne;