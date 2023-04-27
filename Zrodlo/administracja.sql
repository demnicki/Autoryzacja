CREATE CLUSTER moj_klaster (id NUMBER(10));

CREATE INDEX i_klastra ON CLUSTER moj_klaster;

GRANT EXECUTE ON sys.dbms_crypto TO WKSP_KURS;