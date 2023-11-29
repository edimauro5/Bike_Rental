--FUNZIONI

CREATE OR REPLACE FUNCTION DATEDIFF (units VARCHAR(30), start_t TIMESTAMP, end_t TIMESTAMP) 
     RETURNS INT AS $$
   DECLARE
     diff_interval INTERVAL; 
     diff INT = 0;
     years_diff INT = 0;
   BEGIN
     IF units IN ('yy', 'yyyy', 'year', 'mm', 'm', 'month') THEN
       years_diff = DATE_PART('year', end_t) - DATE_PART('year', start_t);
 
       IF units IN ('yy', 'yyyy', 'year') THEN
         -- SQL Server does not count full years passed (only difference between year parts)
         RETURN years_diff;
       ELSE
         -- If end month is less than start month it will subtracted
         RETURN years_diff * 12 + (DATE_PART('month', end_t) - DATE_PART('month', start_t)); 
       END IF;
     END IF;
 
     -- Minus operator returns interval 'DDD days HH:MI:SS'  
     diff_interval = end_t - start_t;
 
     diff = diff + DATE_PART('day', diff_interval);
 
     IF units IN ('wk', 'ww', 'week') THEN
       diff = diff/7;
       RETURN diff;
     END IF;
 
     IF units IN ('dd', 'd', 'day') THEN
       RETURN diff;
     END IF;
 
     diff = diff * 24 + DATE_PART('hour', diff_interval); 
 
     IF units IN ('hh', 'hour') THEN
        RETURN diff;
     END IF;
 
     diff = diff * 60 + DATE_PART('minute', diff_interval);
 
     IF units IN ('mi', 'n', 'minute') THEN
        RETURN diff;
     END IF;
 
     diff = diff * 60 + DATE_PART('second', diff_interval);
 
     RETURN diff;
   END;
   $$ LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION TIMEDIFF (units VARCHAR(30), start_t TIME, end_t TIME) 
     RETURNS INT AS $$
   DECLARE
     diff_interval INTERVAL; 
     diff INT = 0;
   BEGIN
     -- Minus operator for TIME returns interval 'HH:MI:SS'  
     diff_interval = end_t - start_t;
 
     diff = DATE_PART('hour', diff_interval);
 
     IF units IN ('hh', 'hour') THEN
       RETURN diff;
     END IF;
 
     diff = diff * 60 + DATE_PART('minute', diff_interval);
 
     IF units IN ('mi', 'n', 'minute') THEN
        RETURN diff;
     END IF;
 
     diff = diff * 60 + DATE_PART('second', diff_interval);
 
     RETURN diff;
   END;
   $$ LANGUAGE plpgsql;





--SCRIPT DI CREAZIONE

drop table if exists modello cascade;
drop table if exists puntovendita cascade;
drop table if exists addetto cascade;
drop table if exists assegnazione cascade;
drop table if exists telefono cascade;
drop table if exists responsabile cascade;
drop table if exists cliente cascade;
drop table if exists cardprepagata cascade;
drop table if exists acquisto cascade;
drop table if exists bici cascade;
drop table if exists tariffa cascade;
drop table if exists noleggio cascade;
drop table if exists prelievo cascade;
drop table if exists riconsegna cascade;
drop table if exists pagamento cascade;

create table modello(   
    marca varchar(30) not null,
    nome varchar(30) not null,
    grandezzaruote numeric(3,1) not null check(grandezzaruote > 0),
	colore varchar(30) not null,
    categoria varchar(30) not null,
    duratabatteria integer null,
    primary key(marca, nome),
    check (categoria='DaCitta' OR categoria = 'MountainBike' OR categoria = 'Bambino' OR categoria = 'APedalataAssistita' OR categoria = 'Elettrica'),
    check ((categoria='Elettrica' AND duratabatteria is not null AND duratabatteria>0) OR(categoria != 'Elettrica' AND duratabatteria is null))
);

create table puntovendita(
    numid integer primary key,
	via varchar(30) not null,
    civico integer not null,
    citta varchar(30) not null,
    cap char(5) not null,
    unique(via, civico, citta, cap),
    check(numid > 0),
    check(civico > 0),
    check(char_length(cap)=5)  
);
	
create table addetto(
    matricola char(5) primary key check((char_length(matricola)=5)), 
    nome varchar(30) not null,
    cognome varchar(30) not null  
);

create table assegnazione(
    puntovendita integer not null references puntovendita(numid)  
       on delete cascade on update cascade,  
	addetto char(5) not null references addetto(matricola)
       on delete cascade on update cascade,
    primary key(puntovendita, addetto)
);

create table telefono(
    numero varchar(30) primary key,
    addetto char(5) not null references addetto(matricola)
       on delete cascade on update cascade
);

create table responsabile(
    addetto char(5) not null references addetto(matricola)
	   on delete cascade on update cascade,
	puntovendita integer not null references puntovendita(numid)
	   on delete cascade on update cascade, 
	primary key(addetto),
    unique(puntovendita)
);

create table cliente(
    documento varchar(30) primary key,
    via varchar(30) null,
    numerocivico integer null check(numerocivico > 0),
    cap char(5) null check((char_length(cap)=5)), 
    citta varchar(30) null,
    tipo varchar(30) not null check(tipo='Studente' OR tipo='Anziano' OR tipo='Altro'),
    cartadicredito char(16) not null check((char_length(cartadicredito)=16)), 
    check((via is not null AND numerocivico is not null AND cap is not null AND citta is not null)OR
		  (via is null AND numerocivico is null AND cap is null AND citta is null))
);
	   
create table cardprepagata(
    codice char(5) primary key check((char_length(codice)=5)),
    orerimanenti integer null check((orerimanenti is null) OR (orerimanenti is not null AND orerimanenti >= 0))
);

create table acquisto(
    transazione integer not null check(transazione > 0),
    data date not null,
	primary key (transazione, data),
    costo numeric(5,2) not null check(costo > 0),
    metodo varchar(30) not null,
    check (metodo = 'Contanti' OR metodo = 'CartaDiCredito'),
	cliente varchar(30) unique not null references cliente(documento)
       on delete restrict on update cascade,
    cardprepagata char(5) not null references cardprepagata(codice)
       on delete cascade on update cascade,
	unique(cardprepagata)
);

create table bici(
    codice integer primary key check(codice > 0),
    numtelaio varchar(15) not null,
    stato varchar(500) not null,
    marcamodello varchar(30) not null,
    nomemodello varchar(30) not null ,
    puntovendita integer null references puntovendita(numid)
       on update cascade on delete set null,
	foreign key(marcamodello, nomemodello) references modello(marca, nome)
	   on update cascade on delete restrict,  
	unique(numtelaio, marcamodello, nomemodello)
);

create table tariffa(
    nome varchar(30) primary key,
    valore numeric(5,2) not null check(valore > 0),
    tipogiorno varchar(30) not null check (tipogiorno='Feriale' OR tipogiorno='Festivo'),
    tipocliente varchar(30) not null check(tipocliente='Studente' OR tipocliente='Anziano' OR tipocliente='Altro'),
    marcamodello varchar(30) not null,
    nomemodello varchar(30) not null,
    foreign key(marcamodello, nomemodello) references modello(marca, nome)
	   on update cascade on delete cascade  
);

create table noleggio(   
    codice char(6) primary key check((char_length(codice)=6)),  
    tipo varchar(30) not null check(tipo='AdOre' OR tipo='Giornaliero'),
    bici integer not null references bici(codice)
       on delete restrict on update cascade, 
    tariffa varchar(30) not null references tariffa(nome)
	   on delete restrict on update cascade,
	cliente varchar(30) not null references cliente(documento)
	   on delete restrict on update cascade
);

create table prelievo(
    noleggio char(6) primary key references noleggio(codice)
	    on delete cascade on update cascade,
    datainizio date not null,
    orainizio time not null,
    anticipo numeric(5,2) not null check(anticipo>=0),
    cauzione numeric(5,2) not null check(cauzione>0),
	puntovendita integer not null references puntovendita(numid)
	    on delete restrict on update cascade  
);

create table riconsegna(
    noleggio char(6) primary key references noleggio(codice)
	    on delete cascade on update cascade,
	datafine date not null,
    orafine time not null,
	danni boolean not null,
    motivotrattenuta varchar(200) null,
	puntovendita integer not null references puntovendita(numid)
	    on delete restrict on update cascade,  
	check((danni is true AND motivotrattenuta is not null)OR(danni is false AND motivotrattenuta is null))
);


create table pagamento(
    transazione integer not null check(transazione > 0),
    data date not null,
	primary key (transazione, data),
	totale numeric(5,2) not null check(totale >= 0),
    metodo varchar(30) not null check(metodo='Contanti' OR metodo='CartaDiCredito' OR metodo='CardPrepagata'),
    noleggio char(6) not null unique references noleggio(codice)
	   on delete cascade on update cascade
);





--TRIGGER

--Il seguente trigger scatta all'inserimento o alla modifica di una tupla della relazione PuntoVendita e verifica che il cap sia costituito da sole cifre.
--Nel caso in cui così non fosse lancia un'eccezione.

create or replace function ProcCAPpuntoVenditaOnlyDigits() returns trigger as $$
        begin
		if(new.cap !~'[0-9]{5}') then
		     raise exception 'cap in PuntoVendita deve essere di sole cifre';
		end if;
		return new;
		end $$ language plpgsql;
create trigger CAPpuntoVenditaonlyDigits
       before insert or update of cap on puntovendita
	   for each row execute procedure ProcCAPpuntoVenditaOnlyDigits();

--Il seguente trigger scatta all'inserimento o alla modifica di una tupla della relazione Cliente e verifica che il cap sia costituito da sole cifre.
--Nel caso in cui così non fosse lancia un'eccezione.

create or replace function ProcCAPclienteOnlyDigits() returns trigger as $$
        begin
		if(new.cap !~'[0-9]{5}') then
		     raise exception 'cap in Cliente deve essere di sole cifre';
		end if;
		return new;
		end $$ language plpgsql;
create trigger CAPclienteOnlyDigits
       before insert or update of cap on cliente
	   for each row execute procedure ProcCAPclienteOnlyDigits();
	   
--Il seguente trigger scatta all'inserimento o alla modifica di una tupla della relazione Addetto e verifica che la sua matricola sia costituita da sole cifre.
--Nel caso in cui così non fosse lancia un'eccezione.
	   
create or replace function ProcMatricolaAddettoOnlyDigits() returns trigger as $$
        begin
		if(new.matricola !~'[0-9]{5}') then
		     raise exception 'matricola in Addetto deve essere di sole cifre';
		end if;
		return new;
		end $$ language plpgsql;
create trigger MatricolaAddettoOnlyDigits
       before insert or update of matricola on addetto
	   for each row execute procedure ProcMatricolaAddettoOnlyDigits();
	   
--Il seguente trigger scatta all'inserimento o alla modifica di una tupla della relazione CardPrepagata e verifica che il codice sia costituito da sole cifre.
--Nel caso in cui così non fosse lancia un'eccezione.	   
	   
create or replace function ProcCodicePrepagataOnlyDigits() returns trigger as $$
        begin
		if(new.codice !~'[0-9]{5}') then
		     raise exception 'codice in CardPrepagata deve essere di sole cifre';
		end if;
		return new;
		end $$ language plpgsql;
create trigger CodicePrepagataOnlyDigits
       before insert or update of codice on cardprepagata
	   for each row execute procedure ProcCodicePrepagataOnlyDigits();
	   
--Il seguente trigger scatta all'inserimento o alla modifica di una tupla della relazione Noleggio e verifica che il codice sia costituito da sole cifre.
--Nel caso in cui così non fosse lancia un'eccezione.	   
	   
create or replace function ProcCodiceNoleggioOnlyDigits() returns trigger as $$
        begin
		if(new.codice !~'[0-9]{6}') then
		     raise exception 'codice in Noleggio deve essere di sole cifre';
		end if;
		return new;
		end $$ language plpgsql;
create trigger CodiceNoleggioOnlyDigits
       before insert or update of codice on noleggio
	   for each row execute procedure ProcCodiceNoleggioOnlyDigits();
	   
--Il seguente trigger scatta all'inserimento o alla modifica di una tupla della relazione Cliente e verifica che la cartadicredito sia costituita da sole cifre.
--Nel caso in cui così non fosse lancia un'eccezione.	   
	   
create or replace function ProcCartaCreditoOnlyDigits() returns trigger as $$
        begin
		if(new.cartadicredito !~'[0-9]{16}') then
		     raise exception 'cartadicredito in Cliente deve essere di sole cifre';
		end if;
		return new;
		end $$ language plpgsql;
create trigger CartaCreditoOnlyDigits
       before insert or update of cartadicredito on cliente
	   for each row execute procedure ProcCartaCreditoOnlyDigits();
	   
--Il seguente trigger scatta all'inserimento o alla modifica di una tupla della relazione Telefono e verifica che il numero sia costituito da sole cifre.
--Nel caso in cui così non fosse lancia un'eccezione.	   
	   
create or replace function ProcNumTelefonoOnlyDigits() returns trigger as $$
        begin
		if(new.numero !~'^\d{1,30}$') then
		     raise exception 'numero in Telefono deve essere di sole cifre';
		end if;
		return new;
		end $$ language plpgsql;
create trigger NumTelefonoOnlyDigits
       before insert or update of numero on telefono
	   for each row execute procedure ProcNumTelefonoOnlyDigits();

--Il seguente trigger scatta all'inserimento o alla modifica di una tupla della relazione Responsabile e verifica che il responsabile sia anche assegnato al punto vendita che dirige.
--Nel caso in cui così non fosse lancia un'eccezione.

create or replace function ProcResponsabileAncheAssegnato() returns trigger as $$
       begin
	   if(not exists(select * from assegnazione where addetto=new.addetto and puntovendita=new.puntovendita)) then
	        raise exception 'Il responsabile deve anche essere assegnato al punto vendita che dirige';
	   end if;
	   return new;
	   end $$ language plpgsql;
create trigger ResponsabileAncheAssegnato
       before insert or update of addetto on responsabile
	   for each row execute procedure ProcResponsabileAncheAssegnato();

--Il seguente trigger scatta all'inserimento o alla modifica di una tupla della relazione Noleggio e verifica che la bici da noleggia sia disponibile (riconsegnata).
--Nel caso in cui così non fosse lancia un'eccezione.
	   
create or replace function ProcNOLEGGIOconsistency() returns trigger as $$
       begin
	   if(exists(select noleggio.codice from noleggio where noleggio.bici=new.bici except 
				 select riconsegna.noleggio from riconsegna, noleggio where riconsegna.noleggio=noleggio.codice)) then
	        raise exception 'Prima di creare il noleggio è necessario riconsegnare la bici';
	   end if;
	   return new;
	   end $$ language plpgsql;
create trigger NOLEGGIOconsistency
       before insert or update on noleggio
	   for each row execute procedure ProcNOLEGGIOconsistency();

--Il seguente trigger scatta all'inserimento o alla modifica di una tupla della relazione Riconsegna e verifica che esista il prelievo al noleggio associato.
--Nel caso in cui così non fosse lancia un'eccezione.

create or replace function ProcPRELIEVObeforeRICONSEGNA() returns trigger as $$
       begin
	   if(not exists(select * from prelievo where prelievo.noleggio=new.noleggio)) then
	        raise exception 'Prima di creare la riconsegna è necessario creare il prelievo';
	   end if;
	   return new;
	   end $$ language plpgsql;
create trigger PRELIEVObeforeRICONSEGNA
       before insert or update on riconsegna
	   for each row execute procedure ProcPRELIEVObeforeRICONSEGNA();

--Il seguente trigger scatta all'inserimento o alla modifica di una tupla della relazione Pagamento e verifica che esista la riconsegna al noleggio associato.
--Nel caso in cui così non fosse lancia un'eccezione.

create or replace function ProcRICONSEGNAbeforePAGAMENTO() returns trigger as $$
       begin
	   if(not exists(select * from riconsegna where riconsegna.noleggio=new.noleggio)) then
	       raise exception 'Prima di creare il pagamento è necessario creare la riconsegna';
	   end if;
	   return new;
	   end $$ language plpgsql;
create trigger RICONSEGNAbeforePAGAMENTO
       before insert or update on pagamento
	   for each row execute procedure ProcRICONSEGNAbeforePAGAMENTO();

--Il seguente trigger scatta all'inserimento o alla modifica di una tupla della relazione Riconsegna e verifica che la data di fine del noleggio sia posteriore o al più uguale a quella di inizio.
--Nel caso in cui così non fosse lancia un'eccezione.

create or replace function ProcDateconsistency() returns trigger as $$
	   declare
	      app date;
		  att time;
	   begin
	   select datainizio,orainizio into app,att from prelievo where prelievo.noleggio=new.noleggio;
	   if(app > new.datafine) then
	        raise exception 'La data di fine del noleggio deve essere posteriore o al più uguale a quella di inizio';
	   end if;
	   if((app = new.datafine) and (att>=new.orafine)) then
	        raise exception 'Per noleggi che terminano nella stessa giornata in cui sono iniziati, l’ora di fine di riconsegna deve essere successiva a quella di inizio di prelievo';
	   end if;
	   return new;
	   end $$ language plpgsql;
create trigger dateconsistency
       before insert or update on riconsegna
	   for each row execute procedure ProcDateconsistency();

--Il seguente trigger scatta all'inserimento o alla modifica di una tupla della relazione Pagamento e verifica che molteplici aspetti circa i suoi attributi siano corretti.
--Nel caso in cui così non fosse lancia un'eccezione.

create or replace function ProcpagamentiConCardPrepagata() returns trigger as $$
       declare
		  anticipoApp numeric(5,2);
		  tipoApp varchar(30);
		  valoreApp numeric(5,2);
	   begin
	   select anticipo into anticipoApp from prelievo where prelievo.noleggio = new.noleggio;
	   select tipo into tipoApp from noleggio where noleggio.codice = new.noleggio;
	   select valore into valoreApp from tariffa,noleggio where tariffa.nome = noleggio.tariffa and noleggio.codice=new.noleggio;
	   if((new.metodo='CardPrepagata' and anticipoApp != 0) or (new.metodo='CardPrepagata' and new.totale != 0)) then
	       raise exception 'Per pagamenti effettuati con card prepagata l’anticipo ed il totale devono essere zero';
	   end if;
	   if(new.metodo !='CardPrepagata' and new.totale = 0) then
	       raise exception 'Per pagamenti effettuati NON con card prepagata il totale deve essere maggiore di 0';
	   end if;  
	   if(new.metodo !='CardPrepagata' and anticipoApp=0 and tipoApp='Giornaliero') then
	       raise exception 'Un noleggio giornaliero NON pagato con card prepagata NON può avere anticipo=0';
	   end if;
	   if(tipoApp='Giornaliero' and anticipoApp != 0 and anticipoApp != valoreApp*24) then
	       raise exception 'Per noleggi giornalieri con anticipo diverso da 0, l’anticipo stesso deve essere uguale alla tariffa moltiplicata per 24';
	   end if;
	   if(new.totale < anticipoApp) then
	       raise exception 'Il totale del pagamento deve essere maggiore o uguale dell’anticipo';
	   end if;
	   return new;
	   end $$ language plpgsql;
create trigger pagamentiConCardPrepagata
       before insert or update on pagamento
	   for each row execute procedure ProcpagamentiConCardPrepagata();

--Il seguente trigger scatta alla modifica di una tupla della relazione CardPrepagata e verifica che una card prepagata acquistata non abbia un numero di ore rimanenti non definito.
--Nel caso in cui così non fosse lancia un'eccezione.

create or replace function ProcOreRimanentiCardAcquistataMustBeNotNull() returns trigger as $$
       begin 
	   if(exists(select from acquisto where acquisto.cardprepagata=new.codice) and new.orerimanenti is null) then
	       raise exception 'Una card prepagata che è stata acquistata NON può avere un numero di ore rimanenti non definito';
	   end if;
	   return new;
	   end $$ language plpgsql;
create trigger OreRimanentiCardAcquistataMustBeNotNull
       before update of orerimanenti on cardprepagata
	   for each row execute procedure ProcOreRimanentiCardAcquistataMustBeNotNull();

--Il seguente trigger scatta all' inserimento o alla modifica di una tupla della relazione CardPrepagata e verifica che una card prepagata non acquistata abbia un numero di ore rimanenti non definito.
--Nel caso in cui così non fosse lancia un'eccezione.

create or replace function ProcOreRimanentiInserimentoCard() returns trigger as $$
       begin
	   if(not exists(select * from cardprepagata, acquisto where new.codice=acquisto.cardprepagata) and new.orerimanenti is not null) then
	        raise exception 'Una card prepagata che NON è stata acquistata deve avere ore rimanenti uguali a null';
	   end if;
	   return new;
	   end $$ language plpgsql;
create trigger oreRimanentiInserimentoCard
       before insert or update on cardprepagata
	   for each row execute procedure ProcOreRimanentiInserimentoCard();

--Il seguente trigger scatta all' inserimento di una tupla della relazione Acquisto ed esegue il calcolo delle ore rimanenti, inizializzando il rispettivo attributo nella relazione CardPrepagata.

create or replace function ProcOreRimanentiFirstTime() returns trigger as $$
	   declare
	   tariffaCard numeric(5,2) = 1.10;
	   begin
	   update cardprepagata set
	          orerimanenti = new.costo/tariffaCard
			  where codice = new.cardprepagata;
	   return new;
	   end $$ language plpgsql;
create trigger OreRimanentiFirstTime
       after insert on acquisto
	   for each row execute procedure ProcOreRimanentiFirstTime();

--Il seguente trigger scatta all' inserimento di una tupla della relazione Pagamento ed aggiorna l'attributo orerimanenti nella relazione CardPrepagata.
--Nel caso in cui vi fossero problemi lancia un'eccezione.

create or replace function ProcaggiornamentoOreRimanenti() returns trigger as $$
       declare
	   vecchieOrerimanenti integer;
	   datafineApp date;
	   datainizioApp date;
	   orainizioApp time;
	   orafineApp time;
	   difData integer;
	   difOre integer;
	   app integer;
	   sixty numeric(5,2)=60.0;
	   app1 numeric(5,2);
	   codiceApp char(5);
	   begin
	   select cardprepagata.orerimanenti, cardprepagata.codice into vecchieOrerimanenti, codiceApp
	               from pagamento, noleggio, cliente, acquisto, cardprepagata
	               where new.metodo='CardPrepagata' and
				   new.noleggio=noleggio.codice and
				   noleggio.cliente=cliente.documento and
				   noleggio.cliente=acquisto.cliente and
				   acquisto.cardprepagata=cardprepagata.codice ;
	   select datainizio, orainizio, datafine, orafine into datainizioapp, orainizioApp, datafineApp, orafineApp
	          from pagamento, prelievo, riconsegna
			  where new.noleggio=prelievo.noleggio and prelievo.noleggio=riconsegna.noleggio;
	   if(vecchieOrerimanenti = 0) then
	        raise exception 'Sulla cardprepagata non vi sono ore residue!!!';
	   end if;
	   --OreRimanenti = OreRimanenti - [24 * (DataFine - DataInizio) + (OraFine - OraInizio)]
	   difData = DATEDIFF('day', datainizioApp, datafineApp);
	   app = TIMEDIFF('minute', orainizioApp::time, orafineApp::time);
	   if(app=0) then
	       difOre=0;
	   elsif(app>0 and app<30) then
	       difOre=1;
	   else
	       app1=app/sixty;
		   if((app1-(app/60))>=0.5) then
		       difOre=app/60+1;
		   else
		       difOre=app/60;
		   end if;
	   end if;
	   if((vecchieOrerimanenti - ((24 * difData) + difOre))<0) then
	    	raise exception 'Le ore rimanenti non sono sufficienti per effettuare il pagamento';
	   end if;
	   update cardprepagata set
	          orerimanenti = vecchieOrerimanenti - ((24 * difData) + difOre)
			  where cardprepagata.codice=codiceApp and cardprepagata.orerimanenti=vecchieOrerimanenti;
	   return new;
	   end $$ language plpgsql;	
create trigger aggiornamentoOreRimanenti
       after insert on pagamento
	   for each row execute procedure ProcaggiornamentoOreRimanenti();

--Il seguente trigger scatta all' inserimento o alla modifica di una tupla della relazione Pagamento e verifica che l'attributo noleggio in Pagamento sia coerente con il noleggio effettuato.
--Nel caso in cui così non fosse lancia un'eccezione.

create or replace function ProcCheckTotalePagamento() returns trigger as $$
       declare
	   datafineApp date;
	   datainizioApp date;
	   orainizioApp time;
	   orafineApp time;
	   difData integer;
	   difOre integer;
	   totaleCorretto numeric(5,2);
	   valoreApp numeric(5,2);
	   app integer;
	   app1 numeric(5,2);
	   sixty numeric(5,2)=60.0;
	   begin
	   select datainizio, orainizio, datafine, orafine into datainizioapp, orainizioApp, datafineApp, orafineApp
	          from pagamento, prelievo, riconsegna
			  where new.noleggio=prelievo.noleggio and prelievo.noleggio=riconsegna.noleggio;
	   select valore into valoreApp from pagamento, noleggio, tariffa
	                 where new.noleggio=noleggio.codice and noleggio.tariffa=tariffa.nome;
	   difData = DATEDIFF('day', datainizioApp, datafineApp);
	   app = TIMEDIFF('minute', orainizioApp::time, orafineApp::time);
	   if(app=0) then
	       difOre=0;
	   elsif(app>0 and app<30) then
	       difOre=1;
	   else
	       app1=app/sixty;
		   if((app1-(app/60))>=0.5) then
		       difOre=app/60+1;
		   else
		       difOre=app/60;
		   end if;
	   end if;
	   totaleCorretto = (24*difData + difOre)*valoreApp;
	   if(new.metodo!='CardPrepagata' and new.totale != totaleCorretto) then
	          raise notice 'Il totale NON è corretto!!! Dovrebbe essere: %; noleggio: %', totaleCorretto, new.noleggio;
	          raise exception 'Il totale NON è corretto!!!';
	   end if;
	   return new;
	   end $$ language plpgsql;
create trigger checkTotalePagamento
       after insert or update on pagamento
	   for each row execute procedure ProcCheckTotalePagamento();

--Il seguente trigger scatta all' inserimento di una tupla della relazione Prelievo e imposta a null l'attributo puntovendita della relazione Bici.

create or replace function ProcPrelievoBici() returns trigger as $$
       declare
	   biciApp integer;
	   begin
	   select bici.codice into biciApp from noleggio, prelievo, bici
	          where new.noleggio=noleggio.codice and noleggio.bici=bici.codice;
	   update bici set
	   puntovendita = null
	   where bici.codice=biciApp;
	   return new;
	   end $$ language plpgsql;
create trigger PrelievoBici
       after insert on prelievo
	   for each row execute procedure ProcPrelievoBici();

--Il seguente trigger scatta all' inserimento di una tupla della relazione Riconsegna ed assegna alla bici il punto vendita in cui essa è stata riconsegnata.

create or replace function ProcRiconsegnaBici() returns trigger as $$
       declare
	   biciApp integer;
	   begin
	   select bici.codice into biciApp from noleggio, riconsegna, bici
	          where new.noleggio=noleggio.codice and noleggio.bici=bici.codice;
	   update bici set
	   puntovendita = new.puntovendita
	   where bici.codice=biciApp;
	   return new;
	   end $$ language plpgsql;
create trigger RiconsegnaBici
       after insert on riconsegna
	   for each row execute procedure ProcRiconsegnaBici();

--Il seguente trigger scatta alla modifica di una tupla della relazione Tariffa e la impedisce tranne che sull'attributo nome, lanciando un'eccezione.

create or replace function ProcImpedisciAggiornamentoTariffa() returns trigger as $$
    begin
    if(exists (select * from noleggio,tariffa where noleggio.tariffa=old.nome))then
       if(new.valore!=old.valore OR new.tipogiorno!=old.tipogiorno OR new.tipocliente!=old.tipocliente OR
          new.marcamodello!=old.marcamodello OR new.nomemodello!=old.nomemodello)then
		         raise exception 'Impossibile modificare una tariffa a cui corrisponde almeno un noleggio';
	   end if;
	end if;
	return new;
	end $$ language plpgsql;
create trigger ImpedisciAggiornamentoTariffa
       before update on tariffa
	   for each row execute procedure ProcImpedisciAggiornamentoTariffa();





--SCRIPT DI POPOLAMENTO

insert into modello(marca, nome, grandezzaruote, colore, categoria, duratabatteria)
values('Trek', 'District 4', 28, 'grigio', 'DaCitta', null),
      ('Trek', 'Session 8', 29, 'nero', 'MountainBike', null),
      ('Focus', 'Paralane', 29, 'argento', 'DaCitta', null),
	  ('Focus', 'Jam', 29, 'grigio', 'MountainBike', null),
	  ('Specialized', 'MiniP3', 15, 'blu', 'Bambino', null),
	  ('Specialized', 'Kenevo', 29, 'bianco', 'APedalataAssistita', null),
	  ('KTM', 'CityFun Mini', 16.5, 'bianco', 'Bambino', null),
	  ('KTM', 'Macina', 29, 'arancione', 'APedalataAssistita', null),
	  ('KTM', 'Race 271', 29, 'marrone', 'Elettrica', 700),
	  ('Canyon', 'Grail Plus', 29, 'bianco', 'Elettrica', 650);
	  --('Trek', 'Junior Plus', 15, 'blu', 'Bambino', null),
	  --('Trek', 'Rail 9', 29, 'nero', 'APedalataAssistita', null),
	  --('Trek', 'Loft Go', 28, 'celeste', 'Elettrica', 650),
	  --('Focus', 'Sweetie', 16, 'rosa', 'Bambino', null),
	  --('Focus', 'Thron', 29, 'verde', 'APedalataAssistita', null),
	  --('Focus', 'Sam', 29, 'giallo', 'Elettrica', 700),
      --('Specialized', 'CruX', 27.5, 'verde', 'DaCitta', null),
	  --('Specialized', 'P3', 26, 'nero', 'MountainBike', null),
	  --('Specialized', 'Turbo Levo', 29, 'nero', 'Elettrica', 650),
	  --('KTM', 'CityFun 28', 28, 'marrone', 'DaCitta', null),
	  --('KTM', 'Exonic', 27.5, 'arancione', 'MountainBike', null),
	  --('Canyon', 'AeroAd', 29, 'nero', 'DaCitta', null),
	  --('Canyon', 'Spectral', 29, 'grigio', 'MountainBike', null),
	  --('Canyon', 'Spectral Mini', 16, 'grigio', 'Bambino', null),
	  --('Canyon', 'Grail On', 29, 'argento', 'APedalataAssistita', null),

insert into puntovendita(numid, via, civico, citta, cap)
values(1, 'Parigi', 55, 'Bologna', '40121'),
      (2, 'Roma', 121, 'Imola', '40026'),
	  (3, 'Tosarelli', 64, 'Bologna', '40126'),
	  (4, 'Delle Feste', 32, 'Marzabotto', '77777'),
	  (5, 'San Rocco', 23, 'Sasso Marconi', '40033');
	  
insert into addetto(matricola, nome, cognome)
values('00001', 'Salvatore', 'Grimaldi'),
      ('00002', 'Andrea', 'De Gruttola'),
	  ('00003', 'Enrico Maria', 'Di Mauro'),
	  ('00004', 'Allegra', 'Cuzzocrea'),
	  ('00005', 'Guglielmo', 'Barone'),
	  ('00006', 'Francesco', 'La Manna'),
	  ('00007', 'Luigi', 'Grasso'),
	  ('00008', 'Francesco', 'Silano'),
	  ('00009', 'Giovanni', 'Cassiodoro'),
	  ('00010', 'Manuele', 'Memoli'),
	  ('00011', 'Jacopo', 'Memoli'),
	  ('00012', 'Raffaella', 'Meninno'),
	  ('00013', 'Cristian', 'Polidoro'),
	  ('00014', 'Giovanna', 'Saggese'),
	  ('00015', 'Marzio', 'Delli Priscoli');

insert into assegnazione(puntovendita, addetto)
values(1, '00001'),
      (2, '00002'),
	  (3, '00003'),
	  (4, '00004'),
	  (5, '00005'),
	  (1, '00006'),
	  (2, '00006'),
	  (3, '00007'),
	  (4, '00007'),
	  (5, '00008'),
	  (1, '00008'),
	  (2, '00009'),
	  (3, '00009'),
	  (4, '00010'),
	  (5, '00010'),
	  (1, '00011'),
	  (2, '00011'),
	  (3, '00012'),
	  (4, '00012'),
	  (5, '00013'),
	  (1, '00013'),
	  (2, '00014'),
	  (3, '00014'),
	  (4, '00015'),
	  (5, '00015');

insert into telefono(numero, addetto)
values('0512193111', '00001'),
      ('0512193134', '00001'),
	  ('0512193137', '00002'),
	  ('0512193140', '00002'),
	  ('0512193143', '00003'),
	  ('0512193146', '00003'),
	  ('0512193147', '00004'),
	  ('0512193149', '00004'),
	  ('0512193152', '00005'),
	  ('0512193155', '00005'),
	  ('0512193158', '00006'),
	  ('0512193165', '00006'),
	  ('0512193167', '00007'),
	  ('0512193168', '00007'),
	  ('0512193170', '00008'),
	  ('0512193171', '00008'),
	  ('0512193173', '00009'),
	  ('0512193177', '00009'),
	  ('0512193179', '00010'),
	  ('0512193180', '00011'),
	  ('0512193188', '00012'),
	  ('0512193187', '00013'),
	  ('0512193190', '00014'),
	  ('0512191109', '00015');
	  
insert into responsabile(addetto, puntovendita)
values('00001', 1),
      ('00002', 2),
	  ('00003', 3),
	  ('00004', 4),
	  ('00005', 5);	  

insert into cardprepagata(codice, orerimanenti)
values('00001', null),
	  ('00002', null),
	  ('00003', null),
	  ('00004', null),
	  ('00005', null),
	  ('00006', null),
	  ('00007', null),
	  ('00008', null),
	  ('00009', null),
	  ('00010', null),
	  ('00011', null),
	  ('00012', null),
	  ('00013', null),
	  ('00014', null),
	  ('00015', null);

insert into cliente(documento, via, numerocivico, cap, citta, tipo, cartadicredito)
values('CA36495GP', 'Montepruno', 53, '20021', 'Milano', 'Studente', '0897321452345235'),
      ('TR8765FR', 'San Gemelli', 32, '40128', 'Bologna', 'Anziano', '0891221442345315'),
	  ('GF1234YH', 'Europa', 17, '40128', 'Bologna', 'Altro', '1111321452345235'),
	  ('DF6848GR', 'Dei due principati', 341, '40139','Bologna', 'Altro', '2222421452345235'),
      ('GF6758FS', 'Santissima Teresa', 53, '40139', 'Bologna', 'Altro', '0897321388845235'),
	  ('RF543112', 'Delle tre sorelle', 45, '00161', 'Roma', 'Studente', '0897312228845235'),
	  ('RF7895RD', 'Rimembranza', 65, '40139', 'Bologna', 'Altro', '0897321388841999'),
	  ('BB7677BB', 'Della Buona Sorte', 1, '40141', 'Bologna', 'Altro', '0897326666665235'),
	  ('PP6532DD', 'San Pio', 11, '40141', 'Bologna', 'Anziano', '0897327666665235'),
	  ('YU3121LL', 'Dei Malavoglia', 7, '40132', 'Bologna', 'Altro', '0897326666665299'),
	  ('KJ5312KK', 'Nazionale', 543, '40132', 'Bologna', 'Studente', '0812876666665235'),
	  ('RF1234HH', 'Delle Puglie', 98, '40132', 'Bologna', 'Altro', '0897226668376235'),
	  ('TG5999CX', 'San Rocco', 43, '00156', 'Roma', 'Anziano', '0897326666665111'),
	  ('MN5314FF', 'Delle Battaglie', 9, '40139', 'Bologna', 'Altro', '1234326666665235'),
	  ('GT4567AA', 'San Leucio', 4, '40139', 'Bologna', 'Altro', '0897321196665235');

insert into bici(codice, numtelaio, stato, marcamodello, nomemodello, puntovendita)
values(1, 'F61465', 'ok', 'Canyon', 'Grail Plus', 2),
      (19, 'F61466', 'luce posteriore rotta', 'Canyon', 'Grail Plus', 3),
	  (2, 'G61474', 'ok', 'KTM', 'Race 271', 1),
	  (3, 'G61475', 'ok', 'KTM', 'Macina', 2),
	  (18, 'G614WW', 'ok', 'KTM', 'Macina', 1),
	  (4, 'G61477', 'ok', 'KTM', 'CityFun Mini', 3),
	  (17, 'G61111', 'ok', 'KTM', 'CityFun Mini', 2),
	  (5, 'D61477', 'cavalletto mancante', 'Specialized', 'Kenevo', 2),
	  (16, 'D61499', 'ok', 'Specialized', 'Kenevo', 3),
	  (6, 'D61489', 'ok', 'Specialized', 'MiniP3', 2),
	  (20, 'D61490', 'ok', 'Specialized', 'MiniP3', 1),
	  (7, 'E61408', 'ok', 'Focus', 'Jam', 5),
	  (8, 'E63301', 'luce difettosa', 'Focus', 'Paralane', 5),
	  (9, 'J63355', 'ok', 'Trek', 'Session 8', 4),
	  (15, 'J63366', 'vernice mancante in qualche punto', 'Trek', 'Session 8', 5),
	  (10, 'J63367', 'ok', 'Trek', 'District 4', 5),
	  (11, 'J39999', 'ok', 'Trek', 'District 4', 4),
	  (12, 'E68888', 'ok', 'Focus', 'Jam', 3),
	  (13, 'E67777', 'cavalletto mancante', 'Focus', 'Paralane', 4),
	  (14, 'E67788', 'cavalletto rotto', 'Focus', 'Paralane', 1),
	  (21, 'RD3456', 'ok', 'Trek', 'District 4', 1),
	  (22, 'FR567W', 'ok', 'Trek', 'Session 8', 1),
	  (23, '456578', 'sverniciatura', 'Focus', 'Paralane', 1),
	  (24, 'FRGG76', 'ok', 'Focus', 'Jam', 1),
	  (25, 'GTY789', 'ok', 'Specialized', 'MiniP3', 1),
	  (26, '897654', 'ok', 'Specialized', 'Kenevo', 1),
	  (27, '0097GHT', 'ok', 'KTM', 'CityFun Mini', 1),
	  (28, '897HG', 'ok', 'KTM', 'Macina', 1),
	  (29, 'KIHGBK', 'ok', 'KTM', 'Race 271', 1),
	  (30, 'IIIkHJ','ok','Canyon', 'Grail Plus', 1);
	  
insert into tariffa(nome, valore, tipogiorno, tipocliente, marcamodello, nomemodello)
values('District4_feriale_studente', 1, 'Feriale', 'Studente', 'Trek', 'District 4'),
      ('District4_feriale_anziano', 1, 'Feriale', 'Anziano', 'Trek', 'District 4'),
	  ('District4_feriale_altro', 1.20, 'Feriale', 'Altro', 'Trek', 'District 4'),
	  ('District4_festivo_studente', 1.20, 'Festivo', 'Studente', 'Trek', 'District 4'),
	  ('District4_festivo_anziano', 1.20, 'Festivo', 'Anziano', 'Trek', 'District 4'),
	  ('District4_festivo_altro', 1.40, 'Festivo', 'Altro', 'Trek', 'District 4'),
	  ('Session8_feriale_studente', 1.10, 'Feriale', 'Studente', 'Trek', 'Session 8'),
      ('Session8_feriale_anziano', 1.15, 'Feriale', 'Anziano', 'Trek', 'Session 8'),
	  ('Session8_feriale_altro', 1.25, 'Feriale', 'Altro', 'Trek', 'Session 8'),
	  ('Session8_festivo_studente', 1.30, 'Festivo', 'Studente', 'Trek', 'Session 8'),
	  ('Session8_festivo_anziano', 1.30, 'Festivo', 'Anziano', 'Trek', 'Session 8'),
	  ('Session8_festivo_altro', 1.40, 'Festivo', 'Altro', 'Trek', 'Session 8'),
	  ('Paralane_feriale_studente', 0.9, 'Feriale', 'Studente', 'Focus', 'Paralane'),
      ('Paralane_feriale_anziano', 0.9, 'Feriale', 'Anziano', 'Focus', 'Paralane'),
	  ('Paralane_feriale_altro', 1, 'Feriale', 'Altro', 'Focus', 'Paralane'),
	  ('Paralane_festivo_studente', 1.10, 'Festivo', 'Studente', 'Focus', 'Paralane'),
	  ('Paralane_festivo_anziano', 1.10, 'Festivo', 'Anziano', 'Focus', 'Paralane'),
	  ('Paralane_festivo_altro', 1.30, 'Festivo', 'Altro', 'Focus', 'Paralane'),
	  ('Jam_feriale_studente', 2, 'Feriale', 'Studente', 'Focus', 'Jam'),
      ('Jam_feriale_anziano', 2.10, 'Feriale', 'Anziano', 'Focus', 'Jam'),
	  ('Jam_feriale_altro', 2.30, 'Feriale', 'Altro', 'Focus', 'Jam'),
	  ('Jam_festivo_studente', 2.50, 'Festivo', 'Studente', 'Focus', 'Jam'),
	  ('Jam_festivo_anziano', 2.45, 'Festivo', 'Anziano', 'Focus', 'Jam'),
	  ('Jam_festivo_altro', 2.60, 'Festivo', 'Altro', 'Focus', 'Jam'),
	  ('MiniP3_feriale_studente', 0.90, 'Feriale', 'Studente', 'Specialized', 'MiniP3'),
      ('MiniP3_feriale_anziano', 0.90, 'Feriale', 'Anziano', 'Specialized', 'MiniP3'),
	  ('MiniP3_feriale_altro', 1, 'Feriale', 'Altro', 'Specialized', 'MiniP3'),
	  ('MiniP3_festivo_studente', 0.9, 'Festivo', 'Studente', 'Specialized', 'MiniP3'),
	  ('MiniP3_festivo_anziano', 0.9, 'Festivo', 'Anziano', 'Specialized', 'MiniP3'),
	  ('MiniP3_festivo_altro', 1.2, 'Festivo', 'Altro', 'Specialized', 'MiniP3'),
	  ('Kenevo_feriale_studente', 1.55, 'Feriale', 'Studente', 'Specialized', 'Kenevo'),
      ('Kenevo_feriale_anziano', 1.6, 'Feriale', 'Anziano', 'Specialized', 'Kenevo'),
	  ('Kenevo_feriale_altro', 1.8, 'Feriale', 'Altro', 'Specialized', 'Kenevo'),
	  ('Kenevo_festivo_studente', 2, 'Festivo', 'Studente', 'Specialized', 'Kenevo'),
	  ('Kenevo_festivo_anziano', 2, 'Festivo', 'Anziano', 'Specialized', 'Kenevo'),
	  ('Kenevo_festivo_altro', 2, 'Festivo', 'Altro', 'Specialized', 'Kenevo'),
	  ('CityFunMini_feriale_studente', 0.8, 'Feriale', 'Studente', 'KTM', 'CityFun Mini'),
      ('CityFunMini_feriale_anziano', 0.8, 'Feriale', 'Anziano', 'KTM', 'CityFun Mini'),
	  ('CityFunMini_feriale_altro', 1.5, 'Feriale', 'Altro', 'KTM', 'CityFun Mini'),
	  ('CityFunMini_festivo_studente', 1, 'Festivo', 'Studente', 'KTM', 'CityFun Mini'),
	  ('CityFunMini_festivo_anziano', 1, 'Festivo', 'Anziano', 'KTM', 'CityFun Mini'),
	  ('CityFunMini_festivo_altro', 1.1, 'Festivo', 'Altro', 'KTM', 'CityFun Mini'),
	  ('Macina_feriale_studente', 1.2, 'Feriale', 'Studente', 'KTM', 'Macina'),
      ('Macina_feriale_anziano', 1.2, 'Feriale', 'Anziano', 'KTM', 'Macina'),
	  ('Macina_feriale_altro', 1.4, 'Feriale', 'Altro', 'KTM', 'Macina'),
	  ('Macina_festivo_studente', 1.45, 'Festivo', 'Studente', 'KTM', 'Macina'),
	  ('Macina_festivo_anziano', 1.45, 'Festivo', 'Anziano', 'KTM', 'Macina'),
	  ('Macina_festivo_altro', 1.55, 'Festivo', 'Altro', 'KTM', 'Macina'),
	  ('Race271_feriale_studente', 2.5, 'Feriale', 'Studente', 'KTM', 'Race 271'),
      ('Race271_feriale_anziano', 2.5, 'Feriale', 'Anziano', 'KTM', 'Race 271'),
	  ('Race271_feriale_altro', 2.8, 'Feriale', 'Altro', 'KTM', 'Race 271'),
	  ('Race271_festivo_studente', 2.7, 'Festivo', 'Studente', 'KTM', 'Race 271'),
	  ('Race271_festivo_anziano', 2.7, 'Festivo', 'Anziano', 'KTM', 'Race 271'),
	  ('Race271_festivo_altro', 2.8, 'Festivo', 'Altro', 'KTM', 'Race 271'),
	  ('GrailPlus_feriale_studente', 2.10, 'Feriale', 'Studente', 'Canyon', 'Grail Plus'),
      ('GrailPlus_feriale_anziano', 2.10, 'Feriale', 'Anziano', 'Canyon', 'Grail Plus'),
	  ('GrailPlus_feriale_altro', 2.30, 'Feriale', 'Altro', 'Canyon', 'Grail Plus'),
	  ('GrailPlus_festivo_studente', 2.60, 'Festivo', 'Studente', 'Canyon', 'Grail Plus'),
	  ('GrailPlus_festivo_anziano', 2.60, 'Festivo', 'Anziano', 'Canyon', 'Grail Plus'),
	  ('GrailPlus_festivo_altro', 2.65, 'Festivo', 'Altro', 'Canyon', 'Grail Plus');	  

insert into acquisto(transazione, data, costo, metodo, cliente, cardprepagata)
values (1, '2021-05-02', 13.20, 'Contanti', 'TR8765FR', '00001'),
	   (2, '2021-05-02', 13.20, 'CartaDiCredito','GF1234YH', '00002'),
	   (3, '2021-05-02', 26.40, 'Contanti','DF6848GR', '00003'),
	   (1, '2021-05-03', 11.00, 'CartaDiCredito','GF6758FS', '00004'),
	   (2, '2021-05-03', 26.40, 'Contanti','RF7895RD', '00005');

insert into noleggio(codice, tipo, bici, tariffa, cliente)
values ('000001', 'AdOre', 19, 'GrailPlus_festivo_altro', 'GF1234YH');

insert into prelievo(noleggio, datainizio, orainizio, anticipo, cauzione, puntovendita)
values ('000001', '2021-05-02', '08:00:00', 0, 20, 3);

insert into riconsegna(noleggio, datafine, orafine, danni, motivotrattenuta, puntovendita)
values ('000001', '2021-05-02', '10:00:00', false, null, 3);

insert into noleggio(codice, tipo, bici, tariffa, cliente)
values ('000002', 'AdOre', 2, 'Race271_feriale_altro', 'GF6758FS');

insert into prelievo(noleggio, datainizio, orainizio, anticipo, cauzione, puntovendita)
values ('000002', '2021-05-03', '10:00:00', 0, 20, 1);

insert into riconsegna(noleggio, datafine, orafine, danni, motivotrattenuta, puntovendita)
values ('000002', '2021-05-03', '14:00:00', false, null, 1);

insert into noleggio(codice, tipo, bici, tariffa, cliente)
values ('000003', 'AdOre', 18, 'Macina_feriale_altro', 'RF7895RD');

insert into prelievo(noleggio, datainizio, orainizio, anticipo, cauzione, puntovendita)
values ('000003', '2021-05-03', '17:00:00', 0, 20, 1);

insert into riconsegna(noleggio, datafine, orafine, danni, motivotrattenuta, puntovendita)
values ('000003', '2021-05-03', '21:00:00', false, null, 1);

insert into noleggio(codice, tipo, bici, tariffa, cliente)
values ('000004', 'AdOre', 4, 'CityFunMini_feriale_altro', 'RF7895RD');

insert into prelievo(noleggio, datainizio, orainizio, anticipo, cauzione, puntovendita)
values ('000004', '2021-05-04', '09:30:00', 0, 20, 3);

insert into riconsegna(noleggio, datafine, orafine, danni, motivotrattenuta, puntovendita)
values ('000004', '2021-05-04', '13:30:00', false, null, 3);

insert into noleggio(codice, tipo, bici, tariffa, cliente)
values ('000005', 'Giornaliero', 13, 'Paralane_feriale_studente', 'CA36495GP'),
	   ('000006', 'AdOre', 17, 'CityFunMini_feriale_altro', 'RF7895RD');

insert into prelievo(noleggio, datainizio, orainizio, anticipo, cauzione, puntovendita)
values ('000005', '2021-05-05', '11:00:00', 21.60, 20, 4),
	   ('000006', '2021-05-05', '14:00:00', 0, 20, 2);

insert into riconsegna(noleggio, datafine, orafine, danni, motivotrattenuta, puntovendita)
values ('000006', '2021-05-05', '18:00:00', false, null, 2);

insert into noleggio(codice, tipo, bici, tariffa, cliente)
values ('000007', 'AdOre', 15, 'Session8_feriale_altro', 'DF6848GR');

insert into prelievo(noleggio, datainizio, orainizio, anticipo, cauzione, puntovendita)
values ('000007', '2021-05-06', '09:00:00', 6.25, 20, 2);

insert into riconsegna(noleggio, datafine, orafine, danni, motivotrattenuta, puntovendita)
values ('000005', '2021-05-06', '11:00:00', false, null, 4);

insert into noleggio(codice, tipo, bici, tariffa, cliente)
values ('000008', 'AdOre', 8, 'Paralane_feriale_anziano', 'TR8765FR');

insert into prelievo(noleggio, datainizio, orainizio, anticipo, cauzione, puntovendita)
values ('000008', '2021-05-06', '15:45:00', 0, 20, 5);
	   
insert into riconsegna(noleggio, datafine, orafine, danni, motivotrattenuta, puntovendita)
values ('000007', '2021-05-06', '18:30:00', false, null, 2),
       ('000008', '2021-05-06', '20:45:00', false, null, 5);
	   
insert into noleggio(codice, tipo, bici, tariffa, cliente)
values ('000009', 'AdOre', 10, 'District4_feriale_studente', 'RF543112'),
	   ('000010', 'Giornaliero', 20, 'MiniP3_feriale_altro', 'BB7677BB');

insert into prelievo(noleggio, datainizio, orainizio, anticipo, cauzione, puntovendita)
values ('000009', '2021-05-07', '09:15:00', 0, 20, 5),
	   ('000010', '2021-05-07', '10:00:00', 24, 20, 1);

insert into riconsegna(noleggio, datafine, orafine, danni, motivotrattenuta, puntovendita)
values ('000009', '2021-05-07', '17:15:00', false, null, 5);

insert into noleggio(codice, tipo, bici, tariffa, cliente)
values ('000011', 'AdOre', 19, 'GrailPlus_festivo_altro', 'YU3121LL'),
	   ('000012', 'AdOre', 11, 'District4_feriale_anziano', 'PP6532DD');
	   

insert into prelievo(noleggio, datainizio, orainizio, anticipo, cauzione, puntovendita)
values ('000011', '2021-05-08', '08:00:00', 0, 20, 3),
       ('000012', '2021-05-08', '10:00:00', 0, 20, 4);

insert into riconsegna(noleggio, datafine, orafine, danni, motivotrattenuta, puntovendita)
values ('000010', '2021-05-08', '10:00:00', true, 'luce difettosa', 1),
       ('000011', '2021-05-08', '13:00:00', false, null, 3);

insert into noleggio(codice, tipo, bici, tariffa, cliente)
values ('000013', 'AdOre', 4, 'CityFunMini_feriale_altro', 'DF6848GR');

insert into prelievo(noleggio, datainizio, orainizio, anticipo, cauzione, puntovendita)
values ('000013', '2021-05-08', '13:30:00', 0, 20, 3);
	   
insert into riconsegna(noleggio, datafine, orafine, danni, motivotrattenuta, puntovendita)
values ('000013', '2021-05-08', '19:30:00', false, null, 3),
	   ('000012', '2021-05-08', '20:00:00', false, null, 4);
	   
insert into noleggio(codice, tipo, bici, tariffa, cliente)
values ('000014', 'Giornaliero', 5, 'Kenevo_festivo_studente', 'KJ5312KK'),
	   ('000015', 'AdOre', 10, 'District4_festivo_altro', 'RF1234HH'),
	   ('000016', 'AdOre', 13, 'Paralane_festivo_anziano', 'TG5999CX'),
	   ('000017', 'AdOre', 18, 'Macina_festivo_altro', 'MN5314FF');

insert into prelievo(noleggio, datainizio, orainizio, anticipo, cauzione, puntovendita)
values ('000014', '2021-05-09', '07:00:00', 48, 20, 2),
	   ('000015', '2021-05-09', '08:00:00', 0, 20, 5),
	   ('000016', '2021-05-09', '09:15:00', 5.50, 20, 4),
	   ('000017', '2021-05-09', '14:30:00', 0, 20, 1);

insert into riconsegna(noleggio, datafine, orafine, danni, motivotrattenuta, puntovendita)
values ('000016', '2021-05-09', '18:15:00', true, 'freno mancante', 4),
	   ('000015', '2021-05-09', '19:00:00', false, null, 5),
	   ('000017', '2021-05-09', '20:30:00', false, null, 1);

insert into riconsegna(noleggio, datafine, orafine, danni, motivotrattenuta, puntovendita)
values ('000014', '2021-05-10', '07:00:00', false, null, 2);

insert into noleggio(codice, tipo, bici, tariffa, cliente)
values ('000018', 'AdOre', 1, 'Kenevo_feriale_studente', 'KJ5312KK'),
	   ('000019', 'AdOre', 16, 'Kenevo_feriale_altro', 'GT4567AA'),
	   ('000020', 'AdOre', 8, 'Paralane_feriale_anziano', 'TR8765FR');

insert into prelievo(noleggio, datainizio, orainizio, anticipo, cauzione, puntovendita)
values ('000018', '2021-05-10', '08:00:00', 24, 20, 2),
	   ('000019', '2021-05-10', '11:45:00', 18, 20, 3),
	   ('000020', '2021-05-10', '13:00:00', 0, 20, 5);

insert into riconsegna(noleggio, datafine, orafine, danni, motivotrattenuta, puntovendita)
values ('000020', '2021-05-10', '19:00:00', false, null, 5),
	   ('000019', '2021-05-10', '22:45:00', false, null, 3),
	   ('000018', '2021-05-10', '23:30:00', false, null, 2);

insert into noleggio(codice, tipo, bici, tariffa, cliente)
values ('000021', 'AdOre', 2, 'Race271_feriale_studente', 'RF543112'),
	   ('000022', 'AdOre', 19, 'GrailPlus_feriale_studente', 'KJ5312KK'),
	   ('000023', 'AdOre', 4, 'CityFunMini_feriale_anziano', 'TR8765FR'),
	   ('000024', 'AdOre', 18, 'Macina_feriale_anziano', 'PP6532DD');

insert into prelievo(noleggio, datainizio, orainizio, anticipo, cauzione, puntovendita)
values ('000021', '2021-05-11', '07:15:00', 0, 20, 1),
	   ('000022', '2021-05-11', '07:30:00', 0, 20, 3),
	   ('000023', '2021-05-11', '07:45:00', 0, 20, 3),
	   ('000024', '2021-05-11', '08:00:00', 0, 20, 1);

insert into riconsegna(noleggio, datafine, orafine, danni, motivotrattenuta, puntovendita)
values ('000021', '2021-05-11', '09:15:00', false, null, 1),
	   ('000022', '2021-05-11', '09:30:00', false, null, 3),
	   ('000023', '2021-05-11', '09:45:00', false, null, 3),
	   ('000024', '2021-05-11', '10:00:00', false, null, 1);

insert into noleggio(codice, tipo, bici, tariffa, cliente)
values ('000025', 'AdOre', 4, 'CityFunMini_feriale_anziano', 'TR8765FR');

insert into prelievo(noleggio, datainizio, orainizio, anticipo, cauzione, puntovendita)
values ('000025', '2021-05-12', '07:45:00', 0, 20, 3);

--insert into riconsegna(noleggio, datafine, orafine, danni, motivotrattenuta, puntovendita)
--values ('000025', '2021-05-12', '09:45:00', false, null, 3);

insert into pagamento(transazione, data, totale, metodo, noleggio)
values (1, '2021-05-02', 0, 'CardPrepagata', '000001'),
       (1, '2021-05-03', 0, 'CardPrepagata', '000002'),
	   (2, '2021-05-03', 0, 'CardPrepagata', '000003'),
	   (1, '2021-05-04', 0, 'CardPrepagata', '000004'),
	   (1, '2021-05-05', 0, 'CardPrepagata', '000006'),
	   (1, '2021-05-06', 21.60, 'Contanti', '000005'),
	   (3, '2021-05-06', 12.50, 'Contanti', '000007'),
	   (2, '2021-05-06', 4.50, 'Contanti', '000008'),
	   (1, '2021-05-07', 8, 'Contanti', '000009'),
	   (1, '2021-05-08', 24, 'CartaDiCredito', '000010'),
	   (4, '2021-05-08', 13.25, 'CartaDiCredito', '000011'),
	   (3, '2021-05-08', 10, 'Contanti', '000012'),
	   (2, '2021-05-08', 9, 'Contanti', '000013'),
	   (1, '2021-05-09', 15.40, 'Contanti', '000015'),
	   (3, '2021-05-09', 9.90, 'Contanti', '000016'),
	   (2, '2021-05-09', 9.30, 'CartaDiCredito', '000017'),
	   (1, '2021-05-10', 48, 'Contanti', '000014'),
	   (2, '2021-05-10', 5.40, 'Contanti', '000020'),
	   (3, '2021-05-10', 19.80, 'Contanti', '000019'),
	   (4, '2021-05-10', 24.80, 'Contanti', '000018'),
	   (1, '2021-05-11', 5, 'Contanti', '000021'),
	   (2, '2021-05-11', 4.20, 'CartaDiCredito', '000022'),
	   (3, '2021-05-11', 1.60, 'CartaDiCredito', '000023'),
	   (4, '2021-05-11', 2.40, 'Contanti', '000024');
	   --(1, '2021-05-12', 1.60, 'CartaDiCredito', '000025');





--QUERY

--Stampa il documento dei clienti studenti che hanno almeno una volta pagato un noleggio meno di 10 e il numero di volte che lo hanno fatto.

select documento, count(*)
from noleggio, pagamento, cliente
where noleggio.codice=pagamento.noleggio and
      pagamento.totale<10 and
      noleggio.cliente=cliente.documento and
      cliente.tipo='Studente'
group by(documento);

--Stampa tutti i punti vendita in cui sono disponibili tutti i modelli di bici.

select *
from puntovendita PV
where not exists (select M.nome, M.marca
		  		  from modello M		
		 		  except
			   	  select B.nomemodello, B.marcamodello
			 	  from bici B
			 	  where B.puntovendita=PV.numid);

--Stampa resoconto spese per ogni cliente, indicando il tipo di spesa.

select cliente, totale, transazione, data, 'noleggio' as tipo
from noleggio, pagamento
where noleggio.codice=pagamento.noleggio
union all
select documento as cliente, costo as totale, transazione, data, 'card' as tipo
from cliente, acquisto
where cliente.documento=acquisto.cliente
order by cliente;

--Stampa i clienti che hanno noleggiato il modello di bici più costoso con il relativo modello e tariffa.

select cliente.*, tariffa.nomemodello, tariffa.marcamodello, tariffa.valore
from cliente, noleggio, tariffa
where cliente.documento=noleggio.cliente and
	  noleggio.tariffa=tariffa.nome and
	  tariffa.valore=(select max(tariffa.valore)
					  from tariffa, noleggio
					  where tariffa.nome=noleggio.tariffa);

--Stampa tutti i noleggi che non sono stati riconsegnati. (3 metodi)

select *
from noleggio
except 
select noleggio.*
from noleggio, riconsegna
where noleggio.codice=riconsegna.noleggio;

select *
from noleggio
where noleggio.codice not in (select riconsegna.noleggio
				              from riconsegna);

select *
from noleggio
where not exists (select riconsegna.noleggio
				  from riconsegna
				  where noleggio.codice=riconsegna.noleggio);



--VISTE

--La vista produce una tabella composta dalle categorie di bici noleggiate e per ognuna il numero di volte in cui sono state noleggiate.

create view numpercategoria as
select categoria, count(*) as n_volte
from noleggio, bici, modello
where noleggio.bici=bici.codice and
      bici.nomemodello=modello.nome and
	  bici.marcamodello=modello.marca
group by categoria;

--Stampa la categoria di bici noleggiata più volte.

select distinct categoria, n_volte
from numpercategoria
where n_volte=(select max(n_volte)
			   from numpercategoria)
order by categoria;



--La vista produce una tabella composta dai clienti che hanno effettuato almeno un noleggio ed il numero di noleggi che hanno effettuato.

create view numnoleggi as
select cliente, count(*) as num
from noleggio
group by cliente;

--Stampa il cliente che ha effettuato più noleggi

select cliente.*, num
from cliente, numnoleggi
where numnoleggi.cliente=cliente.documento and
	  cliente.documento in (select cliente
						    from numnoleggi
						    where num=(select max(num)
									   from numnoleggi));



--La vista produce una tabella composta dai punti vendita in cui è stato effettuato almeno un noleggio da un cliente di tipo Altro
--e per ogni punto vendita il numero di noleggi effettuati da questo tipo di cliente.

create view numaltroperpv as
select puntovendita, count(*) as numaltro
from riconsegna, noleggio, cliente
where riconsegna.noleggio=noleggio.codice and
	  noleggio.cliente=cliente.documento and
	  cliente.tipo like 'Altro'
group by puntovendita;

--La vista produce una tabella composta dai punti vendita in cui è stato effettuato almeno un noleggio da un cliente di tipo Anziano
--e per ogni punto vendita il numero di noleggi effettuati da questo tipo di cliente.

create view numanzianoperpv as
select puntovendita, count(*) as numanziano
from riconsegna, noleggio, cliente
where riconsegna.noleggio=noleggio.codice and
	  noleggio.cliente=cliente.documento and
	  cliente.tipo like 'Anziano'
group by puntovendita;

--La vista produce una tabella composta dai punti vendita in cui è stato effettuato almeno un noleggio da un cliente di tipo Studente
--e per ogni punto vendita il numero di noleggi effettuati da questo tipo di cliente.

create view numstudenteperpv as
select puntovendita, count(*) as numstudente
from riconsegna, noleggio, cliente
where riconsegna.noleggio=noleggio.codice and
	  noleggio.cliente=cliente.documento and
	  cliente.tipo like 'Studente'
group by puntovendita;

--La vista produce una tabella composta dai noleggi effettuati da clienti studenti ed anziani ed il totale di ogni noleggio.

create view pagamenti_st_an as
select noleggio.codice as noleggio, totale
from pagamento, noleggio, cliente
where pagamento.noleggio=noleggio.codice and
	  noleggio.cliente=cliente.documento and
	  cliente.tipo not like 'Altro';

--Stampa il punto vendita situato a Bologna in cui ogni tipo di cliente ha effettuato un noleggio ed è stato effettuato il maggior numero di noleggi
--da clienti di tipo Altro. Stampare, inoltre, anche il guadagno ricavato da studenti e anziani.

select PV.*, sum(pagamenti_st_an.totale)
from puntovendita PV, riconsegna, noleggio, cliente, pagamenti_st_an
where PV.citta='Bologna' and
	  PV.numid=riconsegna.puntovendita and
	  riconsegna.noleggio=noleggio.codice and
	  noleggio.cliente=cliente.documento and
	  pagamenti_st_an.noleggio=noleggio.codice and
	  PV.numid in (select numaltroperpv.puntovendita 
		     	   from numaltroperpv, numanzianoperpv, numstudenteperpv
				   where numaltroperpv.puntovendita=numanzianoperpv.puntovendita and
					     numanzianoperpv.puntovendita=numstudenteperpv.puntovendita) and
	  PV.numid in (select puntovendita
				   from numaltroperpv
				   where numaltro=(select max(numaltro)
								   from numaltroperpv, puntovendita
								   where numaltroperpv.puntovendita=puntovendita.numid and
								         puntovendita.citta='Bologna'))
group by PV.numid, PV.via, PV.civico, PV.citta, PV.cap;





