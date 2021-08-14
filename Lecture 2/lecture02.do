/**************************************************************
*PROJECT		:	INTRODUCTION TO STATA - LECTURE 2

*PURPUSE		:	Estime Mincer equation for many years

*AUTHOR		:  Ronny M. Condor (ronny.condor@unmsm.edu.pe)

*INPUTS		:	ENAHO - Many modules


*OUTPUTS		:	Summary statistics

*COMMENTS	:	
		
*****************************************************************/


* Estructura de trabajo

global root "C:\Users\Ronny\OneDrive - Universidad Nacional Mayor de San Marcos\Introduction to Stata\03_data"

global raw	"${root}\01_raw"
global codes	"${root}\02_codes"
global cleaned	"${root}\03_cleaned"
global analysis "${root}\04_analysis"
global results	"${root}\05_results"

******************************************************
* 			1. Preparación de la base de datos
******************************************************

* Usamos la base del 2015

************************
*	Módulo 3: Educación
************************

use "${raw}\Modulo 3\2013.dta" , clear 

* Variables que usaremos

//Sexo
codebook p207
recode p207  (2 = 0)
rename p207 male

//Variables geográficas
codebook dominio

gen urban = 1 if estrato <= 6 //Hogares urbanos
replace urban = 0 if estrato > 6 //Hogares rurales

//Alfabetismo
recode p302 2=0
rename p302 literacy

//Nivel educativo
codebook p301a
label list p301a

//Años de educación estimados
codebook p301b p301c
egen    tmp_years = rowmax(p301b p301c)
gen educ = .
replace educ      = tmp_years    if  p301a==3 & tmp_years<6
replace educ      = 6            if (p301a==3 & tmp_years>=6) | p301a==4
replace educ      = 6+tmp_years  if  p301a==5 & tmp_years<=5
replace educ      = 11           if (p301a==5 & tmp_years>=5) | p301a==6
replace educ      = 11+tmp_years if  p301a>=7 & p301a!=. & tmp_years!=.

rename p301a level_educ

/* Experiencia laboral
	Debido a falta de medidas precisas de esta variable, usualmente se aproxima la experiencia laboral 
	como la edad menos los años de educación menos 6(véase Mincer, 1974). 
	Esta solución es muy restrictiva, ya que supone que la persona encontrará 
	trabajo instantáneamente luego de culminar sus estudios. */

gen exp = p208a - educ - 6
label variable exp "experiencia laboral"

//Experiencia al cuadrado
gen exp2=exp^2
label variable exp2 "experiencia al cuadrado"


//Año
gen year=2015

//Ordenamos
order year, first

//Variables relevantes
global key_vars year conglome vivienda hogar codperso

global use_vars male dominio urban literacy educ level_educ

keep $key_vars $use_vars


********************************
*	Módulo 5: Empleo e Ingresos
********************************
use "${raw}\Modulo 5\2013.dta" , clear

d p524a1 p523
codebook p524a1 p523 p530a p538a1 p541a
summ p524a1 p523 p530a p538a1 p541a

foreach var in p524a1 p523 p530a p538a1 p541a {
	replace `var' = . if `var' == 999999 | `var' == 99999
}

//Año
gen year = 2013

* Variables del mercado laboral

/* Fuente: Aragón, Fernando M., and Juan Pablo Rud. 2013. 
 	"Natural Resources and Local Communities: Evidence from a Peruvian Gold Mine." 
	American Economic Journal: Economic Policy, 5 (2): 1-25. */

//Ingreso primario dependiente
gen y_pri_dep = 0 if p524a1 != . & p523 != .

	*Diario (se asume 260 pagos cada año, es decir 260/12 cada mes)
	replace y_pri_dep = p524a1 * 260/12 if p523 == 1

	*Semanal (se asume 52 pagos cada año, es decir 52/12 cada mes)
	replace y_pri_dep   = p524a1 * 52/12  if p523 == 2

	*Quincenal
	replace y_pri_dep   = p524a1 * 2      if p523 == 3

	*Mensual
	replace y_pri_dep   = p524a1 * 1      if p523 == 4

//Ingreso primario independiente
rename p530a y_pri_indep

//Ingreso primario
egen y_pri = rowtotal(y_pri_dep y_pri_indep)  if  !missing(y_pri_dep) | !missing(y_pri_ind)

//Ingreso secundario dependiente e independiente
rename p538a1  y_sec_dep
rename p541a   y_sec_ind

//Ingreso secundario
egen y_sec = rowtotal(y_sec_dep y_sec_ind) 

//Ingreso laboral
egen y_mkt = rowtotal(y_pri y_sec) 

//Variables relevantes
global key_vars year conglome vivienda hogar codperso

global use_vars y_*

keep $key_vars $use_vars

******************************************************
* 					2. Uso de loops y append
******************************************************

************************
*	Módulo 3: Educación
************************

local key_vars year conglome vivienda hogar codperso
local use_vars male dominio urban literacy educ level_educ

qui forvalues yy = 2016/2019 {

di "Ejecutando Módulo 3 `yy'"

use "$raw/Modulo 3/`yy'.dta" , clear


//Sexo
codebook p207
recode p207  (2 = 0)
rename p207 male

//Variables geográficas
codebook dominio

gen urban = 1 if estrato <= 6 //Hogares urbanos
replace urban = 0 if estrato > 6 //Hogares rurales

//Alfabetismo
recode p302 2=0
rename p302 literacy

//Nivel educativo
codebook p301a
label list p301a

//Años de educación estimados
codebook p301b p301c
egen    tmp_years = rowmax(p301b p301c)
gen educ = .
replace educ      = tmp_years    if  p301a==3 & tmp_years<6
replace educ      = 6            if (p301a==3 & tmp_years>=6) | p301a==4
replace educ      = 6+tmp_years  if  p301a==5 & tmp_years<=5
replace educ      = 11           if (p301a==5 & tmp_years>=5) | p301a==6
replace educ      = 11+tmp_years if  p301a>=7 & p301a!=. & tmp_years!=.

rename p301a level_educ

/* Experiencia laboral
	Debido a falta de medidas precisas de esta variable, usualmente se aproxima la experiencia laboral 
	como la edad menos los años de educación menos 6(véase Mincer, 1974). 
	Esta solución es muy restrictiva, ya que supone que la persona encontrará 
	trabajo instantáneamente luego de culminar sus estudios. */

gen exp = p208a - educ - 6
label variable exp "experiencia laboral"

//Experiencia al cuadrado
gen exp2=exp^2
label variable exp2 "experiencia al cuadrado"


//Año
gen year = `yy'

//Ordenamos
order year, first

//Variables relevantes
global key_vars year conglome vivienda hogar codperso

global use_vars male dominio urban literacy educ level_educ

keep `key_vars' `use_vars'

di "Módulo 3 `yy' completado"

sort `key_vars'

save "$raw\tmp_mod3_`yy'", replace

}

* ------------------------
* Append
* ------------------------
local key_vars year conglome vivienda hogar codperso
forvalues yy=2016(1)2019{	
	sort `key_vars'
	append using "$raw\tmp_mod3_`yy'"
	}

save "$raw\mod3.dta", replace	


********************************
*	Módulo 5: Empleo e Ingresos
********************************

local key_vars year conglome vivienda hogar codperso
local use_vars y_*
forvalues yy=2016(1)2019 {

di "Ejecutando Módulo 5 `yy'"
use "$raw/Modulo 5/`yy'.dta" , clear 

d p524a1 p523
codebook p524a1 p523 p530a p538a1 p541a
summ p524a1 p523 p530a p538a1 p541a

foreach var in p524a1 p523 p530a p538a1 p541a {
	replace `var' = . if `var' == 999999 | `var' == 99999
}

//Año
gen year = `yy'

* Variables del mercado laboral

/* Fuente: Aragón, Fernando M., and Juan Pablo Rud. 2013. 
 	"Natural Resources and Local Communities: Evidence from a Peruvian Gold Mine." 
	American Economic Journal: Economic Policy, 5 (2): 1-25. */

//Ingreso primario dependiente
gen y_pri_dep = 0 if p524a1 != . & p523 != .

	*Diario (se asume 260 pagos cada año, es decir 260/12 cada mes)
	replace y_pri_dep = p524a1 * 260/12 if p523 == 1

	*Semanal (se asume 52 pagos cada año, es decir 52/12 cada mes)
	replace y_pri_dep   = p524a1 * 52/12  if p523 == 2

	*Quincenal
	replace y_pri_dep   = p524a1 * 2      if p523 == 3

	*Mensual
	replace y_pri_dep   = p524a1 * 1      if p523 == 4

//Ingreso primario independiente
rename p530a y_pri_indep

//Ingreso primario
egen y_pri = rowtotal(y_pri_dep y_pri_indep)  if  !missing(y_pri_dep) | !missing(y_pri_ind)

//Ingreso secundario dependiente e independiente
rename p538a1  y_sec_dep
rename p541a   y_sec_ind

//Ingreso secundario
egen y_sec = rowtotal(y_sec_dep y_sec_ind) 

//Ingreso laboral
egen y_mkt = rowtotal(y_pri y_sec) 

//Variables relevantes
global key_vars year conglome vivienda hogar codperso

global use_vars y_*

keep `key_vars' `use_vars'

save "$raw\tmp_mod5_`yy'", replace

di "Módulo 5 `yy' completado"

}

* Append
local key_vars year conglome vivienda hogar codperso
forvalues yy=2016(1)2019{	

	sort `key_vars'
	append using "$raw\tmp_mod5_`yy'"
	}

save "$raw\mod5.dta", replace	


* 3. Fusión de bases de datos 
* ============================
use "$raw\tmp_mod3_2017.dta" , clear 

merge 1:1 year conglome vivienda hogar codperso using "$raw\tmp_mod5_2017.dta"


* 4. Análisis
* ============================ 
