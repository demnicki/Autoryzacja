var zapytanie = 'BEGIN metr_2(szerokosc => :szerokosc, dlugosc => :dlugosc, wynik => :wynik); END;';

var zmienne_bindowane = {
    szerokosc: 2,
    dlugosc:   2,
    wynik:     0,
};

zmienne_bindowane.wynik = apex.conn.execute(
    zapytanie,
    {
        szerokosc: { dir: oracledb.BIND_IN, val: zmienne_bindowane.szerokosc, type: oracledb.NUMBER },
        dlugosc:   { dir: oracledb.BIND_IN, val: zmienne_bindowane.dlugosc,  type: oracledb.NUMBER },
        wynik:     { dir: oracledb.BIND_OUT, type: oracledb.NUMBER }
    }
).outBinds.wynik;

console.log(zmienne_bindowane.wynik);