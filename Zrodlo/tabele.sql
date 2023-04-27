CREATE TABLE uzytkownicy(
id                NUMBER DEFAULT ON NULL s_uzytkownicy.NEXTVAL NOT NULL,
login_mail        VARCHAR2(250 CHAR) NOT NULL,
rola              CHAR(1 CHAR) DEFAULT 'k' NOT NULL,
i_prob            NUMBER(1) DEFAULT 3 NOT NULL,
nazwa_uzytkownika VARCHAR2(300 CHAR),
plec              CHAR(1 CHAR) DEFAULT 'm' NOT NULL,
data_utworzenia   DATE DEFAULT CURRENT_TIMESTAMP NOT NULL,
CONSTRAINT c_plec CHECK (lower(plec) in ('m','k')),
CONSTRAINT c_rola CHECK (lower(rola) in ('k','s', 'p')),
CONSTRAINT klucz1 PRIMARY KEY (id),
CONSTRAINT unik1 UNIQUE (login_mail)
)CLUSTER moj_klaster(id);

CREATE TABLE hasla(
id              NUMBER DEFAULT ON NULL s_hasla.NEXTVAL NOT NULL,
id_uzytkownika  NUMBER NOT NULL,
konf_wariant    VARCHAR2(2000 CHAR),
haslo_biezace   VARCHAR2(2000 CHAR),
haslo_stare     VARCHAR2(2000 CHAR),
wariant1        VARCHAR2(2000 CHAR),
wariant2        VARCHAR2(2000 CHAR),
wariant3        VARCHAR2(2000 CHAR),
wariant4        VARCHAR2(2000 CHAR),
wariant5        VARCHAR2(2000 CHAR),
data_zmiany     DATE DEFAULT CURRENT_TIMESTAMP NOT NULL,
CONSTRAINT klucz2 PRIMARY KEY (id),
CONSTRAINT k_uzytk1 FOREIGN KEY (id_uzytkownika) REFERENCES uzytkownicy(id),
CONSTRAINT spr_json CHECK (konf_wariant IS JSON)
);

CREATE TABLE nry_tel(
id_uzytkownika  NUMBER NOT NULL,
numer_tel       VARCHAR2(15 CHAR) NOT NULL,
data_zmiany     DATE DEFAULT CURRENT_TIMESTAMP NOT NULL,
CONSTRAINT klucz3 PRIMARY KEY (numer_tel),
CONSTRAINT k_uzytk5 FOREIGN KEY (id_uzytkownika) REFERENCES uzytkownicy(id)
)CLUSTER moj_klaster(id_uzytkownika);

CREATE TABLE urzadzenia(
id_urzadz      CHAR(6 CHAR) NOT NULL,
id_uzytkownika NUMBER NOT NULL,
typ            CHAR(1 CHAR) DEFAULT 'k' NOT NULL,
kategoria      CHAR(1 CHAR) DEFAULT 'j' NOT NULL,
CONSTRAINT klucz4 PRIMARY KEY (id_urzadz),
CONSTRAINT typ_urzadz CHECK (lower(typ) in ('k','m','g','i')),
CONSTRAINT kat_urzadz CHECK (lower(kategoria) in ('j','z')),
CONSTRAINT k_uzytk8 FOREIGN KEY (id_uzytkownika) REFERENCES uzytkownicy(id)
)CLUSTER moj_klaster(id_uzytkownika);

CREATE TABLE logi_uzytk(
id             NUMBER DEFAULT ON NULL s_logi_uzytk.NEXTVAL NOT NULL,
id_urzadz      CHAR(6 CHAR) NOT NULL,
ip             CHAR(16 CHAR),
agent_klienta  VARCHAR2(500 CHAR),
status         CHAR(1 CHAR) DEFAULT 'n' NOT NULL,
data_logu      DATE DEFAULT CURRENT_TIMESTAMP NOT NULL,
CONSTRAINT klucz5 PRIMARY KEY (id),
CONSTRAINT c_status CHECK (lower(status) in ('u','n')),
CONSTRAINT k_uzytk2 FOREIGN KEY (id_urzadz) REFERENCES urzadzenia(id_urzadz)
)CLUSTER moj_klaster(id_urzadz);

CREATE TABLE tokeny(
id_urzadz        CHAR(6 CHAR) NOT NULL,
token            CHAR(32 CHAR) NOT NULL,
czas_sesji       DATE NOT NULL,
CONSTRAINT k_uzytk6 FOREIGN KEY (id_urzadz) REFERENCES urzadzenia(id_urzadz),
CONSTRAINT unik2 UNIQUE (token)
)CLUSTER moj_klaster(id_urzadz);

CREATE TABLE kategorie_menu(
id             NUMBER DEFAULT ON NULL s_kat_menu.NEXTVAL NOT NULL,
id_uzytkownika NUMBER NOT NULL,
typ            CHAR(1 CHAR) NOT NULL,
nazwa_kat      VARCHAR2(50 CHAR),
CONSTRAINT klucz6 PRIMARY KEY (id),
CONSTRAINT c_typ CHECK (lower(typ) in ('p','d')),
CONSTRAINT k_uzytk7 FOREIGN KEY (id_uzytkownika) REFERENCES uzytkownicy(id)
)CLUSTER moj_klaster(id_uzytkownika);

CREATE TABLE pozycje_menu(
id        NUMBER DEFAULT ON NULL s_poz_menu.NEXTVAL NOT NULL,
id_kat    NUMBER NOT NULL,
typ       CHAR(1 CHAR) NOT NULL,
nazwa_poz VARCHAR2(50 CHAR),
wartosc   VARCHAR2(300 CHAR) NOT NULL,
CONSTRAINT klucz7 PRIMARY KEY (id),
CONSTRAINT c_typ2 CHECK (lower(typ) in ('f','w','z')),
CONSTRAINT k_kat FOREIGN KEY (id_kat) REFERENCES kategorie_menu(id)
)CLUSTER moj_klaster(id_kat);