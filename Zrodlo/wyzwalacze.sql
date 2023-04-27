CREATE OR REPLACE TRIGGER czyszczenie_tokenow  
AFTER INSERT OR UPDATE ON tokeny  
BEGIN
DELETE FROM tokeny WHERE CURRENT_TIMESTAMP > czas_sesji;
END czyszczenie_tokenow;

CREATE OR REPLACE TRIGGER t_kat_menu
BEFORE INSERT OR UPDATE ON kategorie_menu
FOR EACH ROW
BEGIN
:new.nazwa_kat := upper(:new.nazwa_kat);
END t_kat_menu;