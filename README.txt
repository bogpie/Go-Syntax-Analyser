Proiectul analizează elementele de sintaxă ale unui fișier scris în limbajul GO, verificând dacă există
erori.

Se folosește flex version 2.5.4 și C, având un Makefile cu regulile de build, run și clean. Alternativa
pentru regula de run este rularea ./exec input1 (cel default) sau input2.

Se definesc următoarele stări în secțiunea de cod rezervată regulilor RegEx
-   INITIAL, din care se intră într-o nouă funcție la găsirea termenului "func"
-   FUNCTION, prelucrarea de început a unei funcții, prin care se evaluează dacă există o altă funcție cu același nume
-   ARGUMENTS, prelucrarea argumentelor funcțiilor, aceste variabile având un nume de o literă și un tip
-   FUNCTION_TYPE, pentru tipul funcției, se decide dacă funcția returnează sau nu ceva
-   BODY, pentru corpul funcției, se analizează dacă tipul de returnat corespunde cu variabila aflată în return, se
actualizează coada de variabile de inițializat, se verifică erori de refolosire a variabilelor vechi
-   DECLARE_AND_ASSIGN - se prelucreză membrul drept pentru un operator :=, sau =, se folosește variabila isDeclare
pentru tipul operatorului
-   COMMENT - comentarii ce trebuie ignorate

Probleme întâmpinate și soluțiile implementate
-   Implementarea unei reprezentări ușor de înțeles pentru tipuri - se folosesc macro-definiții; în plus, la prelucrarea
 unor variabile le marchez întâi cu PENDING (-1) la parsarea numelui, urmând ca apoi să fie transformat în tipul real
 la găsirea unor informații noi (tipul explicit menționat, sau deducerea din valori)
-   Nu există map-uri în C, iar implementarea lor ar complica implementarea. Variabilele sunt reprezentate de indicele
în alfabet, cu indexare de la 0, al numelui (care poate fi considerat o literă, așa cum se precizează în enunț)
-   Memorarea valorilor am realizat că nu este necesară, ci doar a tipurilor, de aceea folosesc vectorul varType
(exemplu, dacă varType[1] = INT, atunci b este de tipul int)
-   Atribuirea variabilelor în serie - se folosesc două cozi, una pentru numele de variabile și una pentru tipurile de
assignat
-   Utilizând variabile globale, trebuie resetați anumiți parametrii. Folosesc funcția resetFunction unde se
reinițializează informații corespunzătoare metodei, respectiv cozile (prin atribuirea cu 0 a dimensiunii curente a lor)
-   Am decis utilizarea unor opțiuni ajutătoare
        - noyywrap, nu folosesc yywrap, așadar trebuie menționat explicit în cod ca să compileze
        - yylineno, auxiliar pentru găsirea liniei curente, pus la dispoziție de flex
-   Pentru că se folosesc vectori de stringuri, am inclus funcționalități ale bibliotecii string.h, strcmp, strcpy


Observații:
-   Macro-definițiile din zona de cod a expresiilor regulate sunt parțial preluate din curs (numere, cuvinte, ..)
-   Pentru ignorarea comentariilor de tip single-line, sau multi-line, am urmat indicațiile prevăzute de documentația
flex [1], secțiunea [2]
[1] https://www.cs.virginia.edu/~cr4bd/flex-manual/
[2] https://www.cs.virginia.edu/~cr4bd/flex-manual/How-can-I-match-C_002dstyle-comments_003f.html
