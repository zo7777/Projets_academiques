/*Projet SAS sur le classement des equipes de Rugby
Auteurs: Nabil LOUDAOUI; Omar Saip SY; Yann KIBAMBA
date: 17/11/2023
*/
/*mettre la bibliotheque sur laquelle vous voulez recuperer les tableaux finaux*/
libname lib "/home/u62630052/Projet_M2";

/*mettre le chemin du fichier de tournoi de rugby*/
filename fichier 
	"/home/u62630052/Projet_M2/DATA_PROJET_MAS_23-24_Tournoi2023.xls";

/*macros variables qu'on utilisera sur tout le projet*/
%global date_derniere_journee;
%global date_premiere_journee;
%global equipe_grand_chelem;
%global equipe_cuillere_de_bois;
%global equipe_vainqueur;

/*Imports*/
%macro import_fichier(chemin_fichier, lib=work);
	proc import datafile=&chemin_fichier
		out=&lib..equipe dbms=XLS replace;
		sheet=NATION;
		getnames=yes;
	run;

	proc import datafile=&chemin_fichier
		out=&lib..match dbms=XLS replace;
		sheet=MATCH;
		getnames=yes;
	run;

	proc import datafile=&chemin_fichier
		out=&lib..detail_match dbms=XLS replace;
		sheet=DETAIL;
		getnames=yes;
	run;

%mend;

/*Extraire la premiere et la derniere journee*/
%macro derniere_journee(chemin_fichier, lib=work);
	%import_fichier(&chemin_fichier, lib=&lib.);

	/*recherche de la date max*/
	proc summary data=&lib..match noprint;
		var DAT;
		output out=&lib..tab_dat(drop=_freq_ _type_);
	run;

	/*Affectation de la date de la derniere journee a la macro variable*/
	data &lib..tab_dat;
		set &lib..tab_dat;
		where _stat_="MAX";
		call symputx('date_derniere_journee', DAT);
	run;

	/*Formatage de la date de la derniere journee*/
	%let date_derniere_journee = %sysfunc(putn(&date_derniere_journee, 
		mmddyy10.));

	/*recherche de la date min(c a d la date de la premiere journee)*/
	proc summary data=&lib..match noprint;
		var DAT;
		output out=&lib..tab_dat(drop=_freq_ _type_);
	run;

	/*Affectation de la date de la premiere journee a la macro variable*/
	data &lib..tab_dat;
		set &lib..tab_dat;
		where _stat_="MIN";
		call symputx('date_premiere_journee', DAT);
	run;

	/*Formatage de la date de la derniere journee*/
	%let date_premiere_journee = %sysfunc(putn(&date_premiere_journee, 
		mmddyy10.));

	/*suppression du tableau donnant la date max*/
	proc datasets lib=&lib. nolist;
		delete tab_dat;
		run;
	%mend;

	/*Allocation des points a chaque match*/
	%macro game_points(date, chemin_fichier, lib=work);
		%import_fichier(&chemin_fichier, lib=&lib.);

	/*Jointure match et leurs details*/
	data &lib..match_detaille;
		length ANN 8. DAT 8.;
		merge &lib..detail_match &lib..match;
		by JOU MAT EQ_DOM EQ_EXT;
	run;

	%if &date=&date_derniere_journee %then
		%do;

			data &lib..match_detaille;
				length ANN 8. DAT 8.;
				set &lib..match_detaille;
				where DAT <=input("&date", mmddyy10.);
			run;

		%end;
	%else
		%do;

			data &lib..match_detaille;
				length ANN 8. DAT 8.;
				set &lib..match_detaille;
				where DAT <=input(&date, mmddyy10.);
			run;

		%end;

	/*allocation des points a une date donnee*/
	data &lib..points;
		set &lib..match_detaille;

		/*EQUIPE DOMICILE GAGNE AVEC AU MOINS 4 ESSAIS*/
		if (SCO_DOM > SCO_EXT and ESS_DOM>=4) then
			do;
				Pts_DOM=5;

				if(SCO_DOM-SCO_EXT<=7 and ESS_EXT>=4) then
					Pts_EXT=2;
				else if((SCO_DOM-SCO_EXT<=7 and ESS_EXT<4) or (SCO_DOM-SCO_EXT>7 and 
					ESS_EXT>=4)) then
						Pts_EXT=1;
				else
					Pts_EXT=0;
			end;

		/*EQUIPE DOMICILE GAGNE AVEC MOINS DE 4 ESSAIS*/
		else if (SCO_DOM > SCO_EXT and ESS_DOM < 4) then
			do;
				Pts_DOM=4;

				if(SCO_DOM-SCO_EXT<=7 and ESS_EXT>=4) then
					Pts_EXT=2;
				else if((SCO_DOM-SCO_EXT<=7 and ESS_EXT<4) or (SCO_DOM-SCO_EXT>7 and 
					ESS_EXT>=4)) then
						Pts_EXT=1;
				else
					Pts_EXT=0;
			end;

		/*EQUIPE EXTERIEUR GAGNE AVEC AU MOINS 4 ESSAIS*/
		else if (SCO_DOM < SCO_EXT and ESS_EXT>=4) then
			do;
				Pts_EXT=5;

				if(SCO_EXT-SCO_DOM<=7 and ESS_DOM>=4) then
					Pts_DOM=2;
				else if((SCO_EXT-SCO_DOM<=7 and ESS_DOM<4) or (SCO_EXT-SCO_DOM>7 and 
					ESS_DOM>=4)) then
						Pts_DOM=1;
				else
					Pts_DOM=0;
			end;

		/*EQUIPE EXTERIEUR GAGNE AVEC MOINS DE 4 ESSAIS*/
		else if (SCO_DOM < SCO_EXT and ESS_EXT<4) then
			do;
				Pts_EXT=4;

				if(SCO_EXT-SCO_DOM<=7 and ESS_DOM>=4) then
					Pts_DOM=2;
				else if((SCO_EXT-SCO_DOM<=7 and ESS_DOM<4) or (SCO_EXT-SCO_DOM>7 and 
					ESS_DOM>=4)) then
						Pts_DOM=1;
				else
					Pts_DOM=0;
			end;

		/*MATCH NUL DOMICILE avec 4 essais au moins*/
		else if (SCO_DOM=SCO_EXT and ESS_DOM>=4) then
			do;
				Pts_DOM=3;

				if(ESS_EXT>=4) then
					Pts_EXT=3;
				else
					Pts_EXT=2;
			end;

		/*MATCH NUL DOMICILE avec moins de 4 essais*/
		else if (SCO_DOM=SCO_EXT and ESS_DOM<4) then
			do;
				Pts_DOM=2;

				if(ESS_EXT>=4) then
					Pts_EXT=3;
				else
					Pts_EXT=2;
			end;
	run;

%mend;

/*filtrer chaque equipe et son nombre de points*/
%macro team_total_points(team, lib=work);
	data &lib..&team;
		set &lib..points;
		where EQ_DOM="&team" or EQ_EXT="&team";

		if EQ_DOM="&team" then
			Pts=Pts_DOM;
		else if EQ_EXT="&team" then
			Pts=Pts_EXT;
	run;

	proc means data=&lib..&team sum noprint;
		var Pts;
		output out=&lib..total_points_&team SUM=total_pts;
	run;

%mend;

/*classement*/
%macro classement(date, chemin_fichier=fichier, lib=work);
	%import_fichier(&chemin_fichier, lib=&lib.);
	%game_points(&date, &chemin_fichier, lib=&lib.);

	/*creer un tableau pour le classement*/
	data &lib..tableau_classement;
		length EQ $20. NAT $30. PTS 8;
		format PTS best. EQ $20. NAT $30.;
		keep EQ NAT PTS;
	run;

	/* Creer la liste de chaque equipe du tournoi */
	proc sql noprint;
		select distinct EQ, NAT into :team_list separated by ' ', :nat_list separated 
			by ';' from &lib..equipe;
	quit;
	
	%let team_list = &team_list;/* macro variable qui contient chaque equipe */
	
	%let nat_list = &nat_list;/* macro variable qui contient chaque nation */
	
	%let num_teams = %sysfunc(countw(&team_list));/*Compte le nombre d'equipe*/

	/* Boucle sur chaque equipe et cree des tableaux separes */
	%do i=1 %to &num_teams;
		%let team = %scan(&team_list, &i);/* Chercher la i-eme equipe de la liste */
	    %let nat = %scan(&nat_list, &i, ";");/* Chercher la i-eme nation de la liste */
		
		/*filtrer i-eme equipe et ses points*/
		%team_total_points(&team, lib=&lib.);

		/*Cree un tableau pour la i-eme equipe et ses points totaux */
		data &lib..each_team_total_points;
			length EQ $20. NAT $30. PTS 8;
			format PTS best. EQ $20. NAT $30.;
			keep EQ NAT PTS;
			set &lib..total_points_&team(keep=total_pts);
			EQ="&team";
			NAT="&nat";
			PTS=total_pts;
		run;

		/*ajouter i-eme equipe et ses points totaux au tableau_classement*/
		proc append base=&lib..tableau_classement data=&lib..each_team_total_points;
		run;

		/*suppression des tableaux dont on a plus besoin*/
		proc datasets lib=&lib. nolist;
			delete &team;
			delete total_points_&team;
			delete each_team_total_points;
			run;
		%end;

	/*reprocessing the ranking table*/
	data &lib..tableau_classement;
		set &lib..tableau_classement;

		if missing(EQ) then
			delete;
	run;

	/*trier le tableau de classement*/
	proc sort data=&lib..tableau_classement;
		by descending PTS;
	run;

%mend;

/*extraire le vainqueur*/
%macro vainqueur(ranking, lib=work);
	data &lib..vainqueur;
		set &lib..&ranking;

		if _N_=1 then
			output;
	run;

	/*mettre le vainqueur dans une macro variable*/
	data _NULL_;
		set &lib..vainqueur;
		call symputx('equipe_vainqueur', NAT);
	run;

%mend;

/*Les matchs perdus de l'equipe lors de chaque match de la compe*/
%macro defaite_team(team, lib=work);
	/*Creer un tableau qui dit si l'equipe a perdu ou non*/
	data &lib..detail_&team;
		set &lib..match_detaille;
		where EQ_DOM="&team" or EQ_EXT="&team";

		if EQ_DOM="&team" and SCO_DOM<SCO_EXT then
			DEF=1;
		else if EQ_EXT="&team" and SCO_EXT<SCO_DOM then
			DEF=1;
		else
			DEF=0;
	run;

	/*calcule le nombre de defaites de l'equipe en question*/
	proc means data=&lib..detail_&team sum noprint;
		var DEF;
		output out=&lib..nbre_defaite_&team SUM=nbre_defaite;
	run;

%mend;

/*macro pour l'equipe ayant fait une cuillere de bois*/
%macro cuillere_de_bois(date=&date_derniere_journee, chemin_fichier=fichier, 
		lib=work);
	%import_fichier(&chemin_fichier, lib=&lib.);
	%game_points(&date, &chemin_fichier, lib=&lib.);

	/*cree un tableau pour la cuillere de bois*/
	data &lib..tableau_cuillere_bois;
		length EQ $20. NAT $30. NBRE_DEF 8 NBRE_JOURNEES 8;
		format NBRE_DEF best. NBRE_JOURNEES best. EQ $20. NAT $30.;
		keep EQ NAT NBRE_DEF NBRE_JOURNEES;
	run;

	/*calcule le nombre de journees*/
	proc sql noprint;
		select max(JOU) into :nbre_journees from &lib..match_detaille;
	quit;

	%let nbre_journees=&nbre_journees;

	/* Cree une liste de chaque equipe du tournoi */
	proc sql noprint;
		select distinct EQ, NAT into :team_list separated by ' ', :nat_list separated 
			by ';' from &lib..equipe;
	quit;

	%let team_list = &team_list;/* Macro variable qui contient chaque equipe */
	
	%let nat_list = &nat_list;/* Macro variable qui contient chaque nation */

	%let num_teams = %sysfunc(countw(&team_list));/*Compte le nombre d'equipes*/
	
	/* Boucle sur chaque equipe et cree des tableaux separes */
	%do i=1 %to &num_teams;
		%let team = %scan(&team_list, &i);/* Chercher la i-eme equipe de la liste */
		
	    %let nat = %scan(&nat_list, &i, ";");/* Chercher la i-eme nation de la liste */
	   
		%defaite_team(&team, lib=&lib.);

		/*Cree un tableau pour la i-eme equipe ayant perdu tous ses matchs */
		data &lib..each_team_defaites;
			length EQ $20. NAT $30. NBRE_DEF 8 NBRE_JOURNEES 8;
			format NBRE_DEF best. NBRE_JOURNEES best. EQ $20. NAT $30.;
			keep EQ NAT NBRE_DEF NBRE_JOURNEES;
			set &lib..nbre_defaite_&team(keep=nbre_defaite);

			if &nbre_journees=nbre_defaite then
				do;
					EQ="&team";
					NAT="&nat";
					NBRE_DEF=nbre_defaite;
					NBRE_JOURNEES=&nbre_journees;
					call symputx('equipe_cuillere_de_bois', NAT);
				end;
		run;

		/*Ajouter la cuillere de bois au tableau dedie*/
		proc append base=&lib..tableau_cuillere_bois data=&lib..each_team_defaites;
		run;

		/*Suppression des tableaux dont on a plus besoin*/
		proc datasets lib=&lib. nolist;
			delete detail_&team;
			delete each_team_defaites;
			delete total_points_&team;
			delete nbre_defaite_&team;
			run;
		%end;

	/*reprocessing the cuillere de bois table*/
	data &lib..tableau_cuillere_bois;
		set &lib..tableau_cuillere_bois;

		if missing(EQ) then
			delete;
	run;

%mend;

/*Les matchs gagnes de l'equipe*/
%macro victoire_team(team, lib=work);
	data &lib..detail_&team;
		set &lib..match_detaille;
		where EQ_DOM="&team" or EQ_EXT="&team";

		if EQ_DOM="&team" and SCO_DOM>SCO_EXT then
			VIC=1;
		else if EQ_EXT="&team" and SCO_EXT>SCO_DOM then
			VIC=1;
		else
			VIC=0;
	run;

	proc means data=&lib..detail_&team sum noprint;
		var VIC;
		output out=&lib..nbre_victoire_&team SUM=nbre_victoire;
	run;

%mend;

/*macro pour l'equipe ayant fait une cuillere de bois*/
%macro grand_chelem(date=&date_derniere_journee, chemin_fichier=fichier, 
		lib=work);
	%import_fichier(&chemin_fichier, lib=&lib.);
	%game_points(&date, &chemin_fichier, lib=&lib.);

	/*cree un tableau pour le grand chelem*/
	data &lib..tableau_grand_chelem;
		length EQ $20. NAT $30. NBRE_VIC 8 NBRE_JOURNEES 8;
		format NBRE_VIC best. NBRE_JOURNEES best. EQ $20. NAT $30.;
		keep EQ NAT NBRE_VIC NBRE_JOURNEES;
	run;

	/*Extrait le nombre de journees*/
	proc sql noprint;
		select max(JOU) into :nbre_journees from &lib..match_detaille;
	quit;

	%let nbre_journees=&nbre_journees;

	/* Cree une liste de chaque equipe du tournoi */
	proc sql noprint;
		select distinct EQ, NAT into :team_list separated by ' ', :nat_list separated 
			by ';' from &lib..equipe;
	quit;

	%let team_list = &team_list;/* macro variable qui contient chaque equipe */

	%let nat_list = &nat_list;/* macro variable qui contient chaque nation */
	
	%let num_teams = %sysfunc(countw(&team_list));/*Compte le nombre d'equipes*/
	
	/* Boucle sur chaque equipe du tournoi et cree des tableaux separes */
	%do i=1 %to &num_teams;
		%let team = %scan(&team_list, &i);/* Extraire la i-eme equipe du tournoi */
	    %let nat = %scan(&nat_list, &i, ";");/* Extraire la i-eme nation du tournoi */
	   
		%victoire_team(&team, lib=&lib.);

		/*Cree un tableau des equipes ayant gagne tous leurs matchs */
		data &lib..each_team_victoires;
			length EQ $20. NAT $30. NBRE_VIC 8 NBRE_JOURNEES 8;
			format NBRE_VIC best. NBRE_JOURNEES best. EQ $20. NAT $30.;
			keep EQ NAT NBRE_VIC NBRE_JOURNEES;
			set &lib..nbre_victoire_&team(keep=nbre_victoire);

			if &nbre_journees=nbre_victoire then
				do;
					EQ="&team";
					NAT="&nat";
					NBRE_VIC=nbre_victoire;
					NBRE_JOURNEES=&nbre_journees;
					call symputx('equipe_grand_chelem', NAT);
				end;
		run;

		/*Ajoute les equipes ayant gagne tous leurs matchs au tableau grand chelem*/
		proc append base=&lib..tableau_grand_chelem data=&lib..each_team_victoires;
		run;

		/*Suppression des tableaux dont on a plus besoin*/
		proc datasets lib=&lib. nolist;
			delete detail_&team;
			delete each_team_victoire;
			delete total_points_&team;
			delete nbre_victoire_&team;
			delete each_team_victoires;
			run;
		%end;

	/*reprocessing the grand chelem table*/
	data &lib..tableau_grand_chelem;
		set &lib..tableau_grand_chelem;

		if missing(EQ) then
			delete;
	run;

%mend;

/*Macro principale qui execute tout le reste*/
%macro programme_principal(date=&date_derniere_journee, chemin_fichier=fichier, 
		lib=work);
	%import_fichier(&chemin_fichier, lib=&lib.);
	%derniere_journee(&chemin_fichier, lib=&lib.);

	/*cet appel permet de faire le classement a la fin de la competition afin de connaitre le vainqueur*/
	%classement(date=&date_derniere_journee, lib=&lib.);
	%cuillere_de_bois(date=&date_derniere_journee, lib=&lib.);
	%grand_chelem(date=&date_derniere_journee, lib=&lib.);

	/*Attribue 3 points de plus au grand chelem*/
	data &lib..tableau_classement;
		set &lib..tableau_classement;

		if NAT="&equipe_grand_chelem" then
			do;
				PTS=PTS+3;
			end;
	run;

	/*trier le tableau de classement*/
	proc sort data=&lib..tableau_classement;
		by descending PTS;
	run;

	%vainqueur(tableau_classement, lib=&lib.);

	/*cet appel permet de faire le classement a la date choisi par l'utilisateur
	si elle est inferieur a la date de fin de la competition*/
	
	%if %sysfunc(mdy(%scan(&date, 1, '/'), %scan(&date, 2, '/'), %scan(&date, 3, 
		'/'))) <%sysfunc(mdy(%scan(&date_derniere_journee, 1, '/'), 
		%scan(&date_derniere_journee, 2, '/'), %scan(&date_derniere_journee, 3, 
		'/'))) %then
			%do;
			%classement(date=&date, lib=&lib.);
		%end;

	/*Si a la date saisie la competition n'a pas commence, met un WARNING*/
	
	%if %sysfunc(mdy(%scan(&date, 1, '/'), %scan(&date, 2, '/'), %scan(&date, 3, 
		'/'))) <=%sysfunc(mdy(%scan(&date_premiere_journee, 1, '/'), 
		%scan(&date_premiere_journee, 2, '/'), %scan(&date_premiere_journee, 3, 
		'/'))) %then
			%do;
			%put WARNING: A la date que vous avez choisi, 
				la competition n avait pas encore commence;
			%put WARNING: Il n y a pas de classement a cette date;
		%end;

	/*Extrait le nombre de journees*/
	proc sql noprint;
		select max(JOU) into :nbre_journees from &lib..match;
	quit;

	%let nbre_journees=&nbre_journees;

	/*Supprime les tableaux dont on a plus besoin*/
	proc datasets lib=&lib. nolist;
		delete match_detaille;
		delete match;
		delete points;
		delete equipe;
		delete detail_match;
		run;

	/*Traitement du grand chelem s'il n'y en a pas*/
	data &lib..tableau_grand_chelem;
		if 0 then
			set &lib..tableau_grand_chelem nobs=numobs;

		if numobs=0 then
			do;
				EQ="None";
				NAT="None";
				NBRE_JOURNEES=&nbre_journees;
				call symputx('equipe_grand_chelem', NAT);
			end;
		else
			do;
				set &lib..tableau_grand_chelem;
			end;
	run;

	/*Traitement de la cuillere de bois s'il n'y en a pas*/
	data &lib..tableau_cuillere_bois;
		if 0 then
			set &lib..tableau_cuillere_bois nobs=numobs;

		if numobs=0 then
			do;
				EQ="None";
				NAT="None";
				NBRE_JOURNEES=&nbre_journees;
				call symputx('equipe_cuillere_de_bois', NAT);
			end;
		else
			do;
				set &lib..tableau_cuillere_bois;
			end;
	run;

	/*Si la date saisie est apres la fin du tournoi, met ce titre*/
	%if %sysfunc(mdy(%scan(&date, 1, '/'), %scan(&date, 2, '/'), %scan(&date, 3, 
		'/'))) >=%sysfunc(mdy(%scan(&date_derniere_journee, 1, '/'), 
		%scan(&date_derniere_journee, 2, '/'), %scan(&date_derniere_journee, 3, 
		'/'))) %then
			%do;
			title "classement a la fin du tournoi";
		%end;

	/*Sinon met ce titre*/
	%else
		%do;
			title "classement au &date";
		%end;

	proc print data=&lib..tableau_classement;
	run;

	title;
	title "vainqueur du tournoi";

	proc print data=&lib..vainqueur;
	run;

	title;
	title "Grand chelem du tournoi";

	proc print data=&lib..tableau_grand_chelem;
	run;

	title;
	title "Cuillere de bois du tournoi";

	proc print data=&lib..tableau_cuillere_bois;
	run;

	title;
	%put La nation ayant gagne est: &equipe_vainqueur;

	/*Conditions sut comment afficher le grand chelem sur le log*/
	%if "&equipe_grand_chelem" ^="None" %then
		%do;
			%put La nation grand chelem est: &equipe_grand_chelem;
		%end;
	%else %if "&equipe_grand_chelem"="None" %then
		%do;
			%put Il n y a pas de nation grand chelem;
		%end;

	/*Conditions sut comment afficher la cuillere de bois sur le log*/
	%if "&equipe_cuillere_de_bois" ^="None" %then
		%do;
			%put La nation cuillere de bois est: &equipe_cuillere_de_bois;
		%end;
	%else %if "&equipe_cuillere_de_bois"="None" %then
		%do;
			%put Il n y a pas de nation cuillere de bois;
		%end;
%mend;

/*P1: Si vous voulez recuperer les tableaux sur votre bibliotheque:
Etape 1: Veuillez mettre le chemin de votre bibliotheque sur la ligne 7 du programme;
Etape 2: Puis taper la commande lib=lib dans la macro %programme_principal.
ou copier le code suivant(apres avoir fait la premiere etape):
%programme_principal(lib=lib);

P2: Si vous souhaitez voir le classement a une date que vous souhaitez:
Saisissez: %programme_principal(date='date_choisi');
Attention!! La date doit etre au format mm/jj/aaaa et entre apostrophes (pas entre guillemets).

P3: Si vous souhaitez voir le classement a une date que vous souhaitez et
recuperer les tableaux sur votre bibliotheque:
Suivez les etapes du P1 et du P2.
*/

%programme_principal()