CREATE OR REPLACE PROCEDURE metr_2(
		dlugosc   IN NUMBER,
		szerokosc IN NUMBER,
		wynik     OUT NUMBER
		)
	IS
	BEGIN
		wynik := szerokosc * dlugosc;
	END;