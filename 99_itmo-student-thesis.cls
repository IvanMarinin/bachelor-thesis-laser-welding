\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{itmo-student-thesis}[2023/04/16 v1.4.5]
\RequirePackage{xkvltxp}
\LoadClass[14pt,a4paper]{extreport}

%% Обработка опций пакета

\newif\if@shouldusexelatex
\newif\if@shouldmakespecification
\newif\if@shouldmakeannotation
\newif\if@shouldmaketitlepage@ru
\newif\if@shouldmakespecification@ru
\newif\if@shouldmakeannotation@ru

\newcommand{\@babeloptions}{english,russian}

\RequirePackage{xkeyval}

\DeclareOptionX{times}{\@shouldusexelatextrue}
\DeclareOptionX{specification}{\@shouldmakespecificationtrue}
\DeclareOptionX{annotation}{\@shouldmakeannotationtrue}
\DeclareOptionX{specification-extra-ru}{\@shouldmakespecification@rutrue}
\DeclareOptionX{annotation-extra-ru}{\@shouldmakeannotation@rutrue}
\DeclareOptionX{titlepage-extra-ru}{\@shouldmaketitlepage@rutrue}
\DeclareOptionX{languages}{\renewcommand{\@babeloptions}{#1}}

\ProcessOptionsX\relax

\if@shouldusexelatex
    \RequirePackage{fontspec}
    \defaultfontfeatures{Ligatures={TeX},Renderer=Basic}
    \setmainfont[Ligatures={TeX,Historic}]{Times New Roman}
    \setsansfont{Arial}
    \setmonofont{Courier New}
\else
    \RequirePackage{paratype}
\fi

%% Конфигурируем babel

\RequirePackage[\@babeloptions]{babel}
\RequirePackage{csquotes}
\RequirePackage{iflang}

%% Формируем отступы

\RequirePackage[top=2cm, bottom=2cm, left=3cm, right=1.5cm]{geometry}

%% Эти пакеты слишком часто используются, чтобы их не включать

\RequirePackage{amsmath}
\RequirePackage{amssymb}
\RequirePackage{amsthm}
\RequirePackage{amsfonts}
\RequirePackage{amsxtra}
\RequirePackage{tikz}
\usetikzlibrary{arrows}

%% Делает запятую в формулах более интеллектуальной, например:
%% $1,5x$ будет читаться как полтора икса, а не один запятая пять иксов.
%% Однако если написать $1, 5x$, то все будет как прежде.
\RequirePackage{icomma}

%% Поддержка цветов и чего-то еще графического, в том числе в таблицах.

\RequirePackage{graphicx}
\RequirePackage{subcaption}
\RequirePackage{colortbl}

%% Цветные заметки

\RequirePackage{xcolor}
\newcommand{\rednote}[1]{\textcolor{red}{#1}}
\newcommand{\bluenote}[1]{\textcolor{blue}{#1}}
\newcommand{\greennote}[1]{\textcolor{green!50!black}{#1}}

%% Этот пакет используется для некоторых таблиц и других визуальных элементов.

\RequirePackage{tabularx}

%% Расположение номеров страниц - как и в диссертации.

\RequirePackage{fancyhdr}

%% Делаем правильные подписи в правильных местах.

\RequirePackage{caption}
\RequirePackage{floatrow}

%% Тем, кому нужны листинги, должны использовать \begin{algorithm}\end{algorithm}
%% в качестве флоатов.

\RequirePackage{algorithm}
\floatname{algorithm}{\@listingname}

%% Не знаю, надо оно здесь или нет, но пусть будет.

\RequirePackage{algorithmicx}
\RequirePackage{algpseudocode}

%% Перечисления по умолчанию слишком разрежены.

\RequirePackage{enumitem}
\setlist{nosep}

%% Полуторный межстрочный интервал
\RequirePackage{setspace}
\onehalfspacing

%% Абзацный отступ по ГОСТу - пять букв. Это примерно столько.

\setlength{\parindent}{1.25cm}

%% Не используем буллеты.

\renewcommand\labelitemi{---}

%% На первом уровне нумерованных списков ставим русские буквы, на втором - цифры.

%%% asbuk работал бы неплохо, но он включает в нумерацию букву "з", которую ГОСТ не разрешает. И, может быть, что-то еще.

\def\asbukx#1{\expandafter\@asbukx\csname c@#1\endcsname}
\def\@asbukx#1{\ifcase#1\or a\or б\or в\or г\or д\or е\or ж\or и\or к\or л\or м\or н\or п\or р\or с\or т\or у\or ф\or х\or ц\or ш\or щ\or э\or ю\or я\fi}

\def\Asbukx#1{\expandafter\@Asbukx\csname c@#1\endcsname}
\def\@Asbukx#1{\ifcase#1\or А\or Б\or В\or Г\or Д\or Е\or Ж\or И\or К\or Л\or М\or Н\or П\or Р\or С\or Т\or У\or Ф\or Х\or Ц\or Ш\or Щ\or Э\or Ю\or Я\fi}

\AddEnumerateCounter{\Asbukx}{\@Asbukx}{М}
\AddEnumerateCounter{\asbukx}{\@asbukx}{м}

\renewcommand\labelenumii{\arabic{enumii})}
\renewcommand\theenumii{\arabic{enumii}}

\newcommand{\@iflfe}[2]{#1}

\newcommand*{\@tablecontinuation}[1]{Table~#1, continued}
\newcommand*{\@chaptername}{CHAPTER}
\newcommand*{\@introductionname}{INTRODUCTION}
\newcommand*{\@conclusionname}{CONCLUSION}
\newcommand*{\@appendixname}{APPENDIX}
\newcommand*{\@appendixcounter}{\Alph{chapter}}
\newcommand*{\@proofname}{Proof}
\newcommand*{\@referencesname}{REFERENCES}
\newcommand*{\@chapterconclusion}{Conclusions on Chapter}
\newcommand*{\@listingname}{Listing}

\newcommand*{\@theorem@theorem}{Theorem}
\newcommand*{\@theorem@proposition}{Proposition}
\newcommand*{\@theorem@corollary}{Corollary}
\newcommand*{\@theorem@lemma}{Lemma}
\newcommand*{\@theorem@question}{Question}
\newcommand*{\@theorem@conjecture}{Conjecture}
\newcommand*{\@theorem@assumption}{Assumption}
\newcommand*{\@theorem@definition}{Definition}
\newcommand*{\@theorem@notation}{Notation}
\newcommand*{\@theorem@condition}{Condition}
\newcommand*{\@theorem@example}{Example}

\addto{\captionsenglish}{%
\renewcommand{\@iflfe}[2]{#1}%
\renewcommand*{\figurename}{Figure}%
\renewcommand*{\contentsname}{Contents}%
\renewcommand*{\labelenumi}{\alph{enumi})}%
\renewcommand*{\theenumi}{\alph{enumi}}%
\renewcommand*{\@tablecontinuation}[1]{Table~#1, continued}%
\renewcommand*{\@chaptername}{CHAPTER}%
\renewcommand*{\@introductionname}{INTRODUCTION}%
\renewcommand*{\@conclusionname}{CONCLUSION}%
\renewcommand*{\@appendixname}{APPENDIX}%
\renewcommand*{\@appendixcounter}{\Alph{chapter}}%
\renewcommand*{\@proofname}{Proof}%
\renewcommand*{\@referencesname}{REFERENCES}%
\renewcommand*{\@chapterconclusion}{Conclusions on Chapter}%
\renewcommand*{\@listingname}{Listing}%
\renewcommand*{\@theorem@theorem}{Theorem}%
\renewcommand*{\@theorem@proposition}{Proposition}%
\renewcommand*{\@theorem@corollary}{Corollary}%
\renewcommand*{\@theorem@lemma}{Lemma}%
\renewcommand*{\@theorem@question}{Question}%
\renewcommand*{\@theorem@conjecture}{Conjecture}%
\renewcommand*{\@theorem@assumption}{Assumption}%
\renewcommand*{\@theorem@definition}{Definition}%
\renewcommand*{\@theorem@notation}{Notation}%
\renewcommand*{\@theorem@condition}{Condition}%
\renewcommand*{\@theorem@example}{Example}%
}

\addto{\captionsrussian}{%
\renewcommand{\@iflfe}[2]{#2}%
\renewcommand*{\figurename}{Рисунок}%
\renewcommand*{\contentsname}{Содержание}%
\renewcommand*{\labelenumi}{\asbukx{enumi})}%
\renewcommand*{\theenumi}{\asbukx{enumi}}%
\renewcommand*{\@tablecontinuation}[1]{Продолжение таблицы~#1}%
\renewcommand*{\@chaptername}{ГЛАВА}%
\renewcommand*{\@introductionname}{ВВЕДЕНИЕ}%
\renewcommand*{\@conclusionname}{ЗАКЛЮЧЕНИЕ}%
\renewcommand*{\@appendixname}{ПРИЛОЖЕНИЕ}%
\renewcommand*{\@appendixcounter}{\Asbukx{chapter}}%
\renewcommand*{\@proofname}{Доказательство}%
\renewcommand*{\@referencesname}{СПИСОК ИСПОЛЬЗОВАННЫХ ИСТОЧНИКОВ}%
\renewcommand*{\@chapterconclusion}{Выводы по главе}%
\renewcommand*{\@listingname}{Листинг}%
\renewcommand*{\@theorem@theorem}{Теорема}%
\renewcommand*{\@theorem@proposition}{Утверждение}%
\renewcommand*{\@theorem@corollary}{Следствие}%
\renewcommand*{\@theorem@lemma}{Лемма}%
\renewcommand*{\@theorem@question}{Вопрос}%
\renewcommand*{\@theorem@conjecture}{Гипотеза}%
\renewcommand*{\@theorem@assumption}{Предположение}%
\renewcommand*{\@theorem@definition}{Определение}%
\renewcommand*{\@theorem@notation}{Обозначение}%
\renewcommand*{\@theorem@condition}{Условие}%
\renewcommand*{\@theorem@example}{Пример}%
}

%% Многостраничные таблицы в гостовском формате. Аргументы:
%% 1 - имя, по которому ссылаемся
%% 2 - подпись
%% 3 - строка форматирования столбцов (как в tabular)
%% 4 - заголовки столбцов (первая строчка, которая будет везде повторяться)
%% 5 - число столбцов (не осилил вычислить его из значения 3)

\newenvironment{nirtable}[5]{
\begin{longtable}{#3}\caption{#2}\label{#1}
\\\hline #4 \\\hline \endfirsthead
\multicolumn{#5}{r}{\normalsize\@tablecontinuation{\thetable}} \\\hline #4 \endhead
}{\end{longtable}}
                    
%% Библиография по ГОСТу. Используем только бибер.

\RequirePackage[
    backend=biber,
    bibencoding=utf8,
    sorting=none,
    sortcites=true,
    bibstyle=gost-numeric,
    citestyle=numeric-comp,
    autolang=other
]{biblatex}

%% Патчи к стилевику библиографии.

% biblatex-3.4 и biblatex-gost
% Эти штуки появились недавно, и кажется, что не во всех дистрибутивах они настроены правильно.
% В любом случае, эта функциональность нам не нужна, ее можно заткнуть таким вот образом.
\providecommand{\datecircaprint}{}
\providecommand{\dateeraprintpre}[1]{}
\providecommand{\mkyearzeros}{}
\providecommand{\dateeraprint}[1]{}
\providecommand{\dateuncertainprint}{}

\renewbibmacro*{//}{\nopunct\printtext{\addspace\mbox{//}\addnbspace}}
\renewcommand*{\newblockpunct}{\textemdash\addnbspace\bibsentence}
\DeclareFieldFormat*{pages}{\mkpageprefix[bookpagination][\mbox]{#1}}
\DeclareFieldFormat*{labelnumberwidth}{#1}
\DefineBibliographyStrings{english}{pages={p\adddot}}
\DefineBibliographyExtras{russian}{\protected\def\bibrangedash{\textendash\penalty\hyphenpenalty}}

% Это ставит сначала русские, потом иностранные источники

\DeclareSourcemap{
    \maps[datatype=bibtex]{
        \map{
            \step[fieldsource=langid, match=russian, final]
            \step[fieldset=presort, fieldvalue={a}]
         }
         \map{
            \step[fieldsource=langid, notmatch=russian, final]
            \step[fieldset=presort, fieldvalue={z}]
         }
    }
}

% Добавляем чей-то драйвер от online, чтобы "электронный ресурс" отражался по ГОСТу.

\DeclareBibliographyDriver{online}{%
\usebibmacro{bibindex}%
\usebibmacro{begentry}%
\usebibmacro{heading}%
\newunit
\usebibmacro{author/editor}%
\setunit*{\labelnamepunct}%
\usebibmacro{title}%
\addspace\foreignlanguage{russian}{[Электронный ресурс]}
\setunit{\addcolondelim}%
\usebibmacro{translation}%
\def\bbx@gost@respdelim{\setunit{\respdelim}}% ----- Resp starts -----
\usebibmacro{byauthor}%
\setunit*{\resppunct}%
\iflistundef{organization}
  {}
  {\setrespdelim%
   \printlist{organization}%
   \setunit*{\resppunct}}%
\usebibmacro{credits}%
\setunit*{\resppunct}%
\usebibmacro{byeditor}%
\setunit*{\resppunct}%
\usebibmacro{bytranslator+others}%
\newunit\newblock
\printfield{version}%
\newunit\newblock
\printlist[semicolondelim]{specdata}%
\newunit\newblock
\usebibmacro{date}%
\newunit\newblock
\printupdate%
\newunit\newblock
\printfield{systemreq}%
\newunit\newblock
\usebibmacro{doi+eprint+url+note}%
\newunit\newblock
\usebibmacro{addendum+pubstate}%
\setunit{\bibpagerefpunct}\newblock
\usebibmacro{pageref}%
\newunit\newblock
\usebibmacro{related:init}%
\usebibmacro{related}%
\usebibmacro{finentry}}

%% Счетчики. Для всего, кроме страниц, используем totcount, для страниц используем pageslts. Если надо.

%\RequirePackage{pageslts} % В текущей версии шаблона нет объема работы. Удивительно, но да.

\RequirePackage{totcount}
\RequirePackage{longtable}
\regtotcounter[auxfile=\jobname.tct]{figure}
\regtotcounter[auxfile=\jobname.tct]{table}
\regtotcounter[auxfile=\jobname.tct]{algorithm}
\newtotcounter[auxfile=\jobname.tct]{citnum}
\newtotcounter[auxfile=\jobname.tct]{appendix}
\AtEveryBibitem{\clearfield{addendum}}

%% Большая пачка определений теорем.

\newtheoremstyle{theoremstyle}{0pt}{0pt}{}{1cm}{\itshape}{.}{.5em}{}
\theoremstyle{theoremstyle}

\newtheorem{theorem}{\@theorem@theorem}
\newtheorem{prop}[theorem]{\@theorem@proposition}
\newtheorem{corollary}[theorem]{\@theorem@corollary}
\newtheorem{lemma}[theorem]{\@theorem@lemma}
\newtheorem{question}[theorem]{\@theorem@question}
\newtheorem{conjecture}[theorem]{\@theorem@conjecture}
\newtheorem{assumption}[theorem]{\@theorem@assumption}
\newtheorem{definition}[theorem]{\@theorem@definition}
\newtheorem{notation}[theorem]{\@theorem@notation}
\newtheorem{condition}[theorem]{\@theorem@condition}
\newtheorem{example}[theorem]{\@theorem@example}

\renewcommand{\proof}[1][]{\textit{\@proofname\ifthenelse{\equal{#1}{}}{}{ (#1)}}.~}

%% Листинги, по умолчанию — Python

\RequirePackage{listings}
\definecolor{darkblue}{rgb}{0,0,0.5}
\definecolor{darkgreen}{rgb}{0,0.5,0}

\lstset{
    language=Python,
    extendedchars=\true,
    tabsize=4,
    keywordstyle=\color{darkblue},
    commentstyle=\color{gray},
    stringstyle=\color{darkgreen},
    breaklines=true,
    showstringspaces=false,
    basicstyle=\small
}

%% Все флоаты нумеруем глобально. Формулы - тоже.

\RequirePackage{chngcntr}
\counterwithout{figure}{chapter}
\counterwithout{table}{chapter}
\counterwithout{algorithm}{chapter}
\counterwithout{algorithm}{section}
\counterwithout{algorithm}{subsection}
\counterwithout{equation}{chapter}

\AtBeginDocument{%
  \let\c@lstlisting\c@algorithm
  \let\thelstlisting\thealgorithm
  \let\ftype@lstlisting\ftype@algorithm % give the floats the same precedence
  \counterwithout{lstlisting}{chapter}
  \counterwithout{lstlisting}{section}
  \counterwithout{lstlisting}{subsection}
}
     

%% "Тонкая" настройка теховских штрафов при формировании абзацев.

\sloppy
\binoppenalty=10000
\relpenalty=10000
\clubpenalty=10000
\widowpenalty=10000

%% Подписи к рисункам, таблицам, листингам.

\floatstyle{plaintop}
\restylefloat{algorithm}

\floatsetup[figure]{style=plain, capposition=bottom}
\captionsetup[figure]{
    labelsep=endash,
    singlelinecheck=false,
    labelfont={normalsize,md},
    justification=centering,
    position=bottom
}
\floatsetup[table]{style=plain, capposition=top}
\captionsetup[table]{
    labelsep=endash,
    singlelinecheck=false,
    labelfont={normalsize,md},
    justification=justified,
    position=top
}
\floatsetup[algorithm]{style=plain, capposition=top}
\captionsetup[algorithm]{
    labelsep=endash,
    singlelinecheck=false,
    labelfont={normalsize,md},
    justification=justified,
    position=top
}
\floatsetup[lstlisting]{style=plain, capposition=top}
\captionsetup[lstlisting]{
    labelsep=endash,
    singlelinecheck=false,
    labelfont={normalsize,md},
    justification=justified,
    position=top
}

%% Переопределение библиографии. Может, можно и проще, но сделал так.

\defbibheading{trueHeading}{%
\chapter*{\@referencesname}%
\addcontentsline{toc}{chapter}{\@referencesname}}

\newcommand{\printmainbibliography}{
\printbibliography[heading=trueHeading]%
%%% Считаем, какие границы у пяти- и десятилетней давности
\newcounter{@yearminusfive@src}%
\newcounter{@yearminusten@src}%
\setcounter{@yearminusfive@src}{\theyear}%
\addtocounter{@yearminusfive@src}{-5}%
\def\@yearminusfive{\value{@yearminusfive@src}}%
\setcounter{@yearminusten@src}{\theyear}%
\addtocounter{@yearminusten@src}{-10}%
\def\@yearminusten{\value{@yearminusten@src}}%
%%% Компоненты фильтров
\newcommand{\@iffiveyears}{\iffieldint{year}{\ifnumless{\thefield{year}}{\@yearminusfive}{\skipentry}{}}{\skipentry}}%
\newcommand{\@iftenyears}{\iffieldint{year}{\ifnumless{\thefield{year}}{\@yearminusfive}{\ifnumless{\thefield{year}}{\@yearminusten}{\skipentry}{}}{\skipentry}}{\skipentry}}%
\newcommand{\@ifveryold}{\iffieldint{year}{\ifnumless{\thefield{year}}{\@yearminusten}{}{\skipentry}}{}}%
\newcommand{\@ifrussian}{\iffieldundef{langid}{}{\iffieldequalstr{langid}{russian}{}{\skipentry}}}%
\newcommand{\@ifforeign}{\iffieldundef{langid}{\skipentry}{\iffieldequalstr{langid}{russian}{\skipentry}{}}}%
%%% Сами фильтры
\defbibcheck{bibch@russiansourcesfiveyears}{\@iffiveyears\@ifrussian}%
\defbibcheck{bibch@russiansourcestenyears}{\@iftenyears\@ifrussian}%
\defbibcheck{bibch@russiansourcesveryold}{\@ifveryold\@ifrussian}%
\defbibcheck{bibch@foreignsourcesfiveyears}{\@iffiveyears\@ifforeign}%
\defbibcheck{bibch@foreignsourcestenyears}{\@iftenyears\@ifforeign}%
\defbibcheck{bibch@foreignsourcesveryold}{\@ifveryold\@ifforeign}%
\@countsourceswhere{}{citnum}%
\@countsourceswhere{check=bibch@russiansourcesfiveyears}{c@russiansourcesfiveyears}%
\@countsourceswhere{check=bibch@russiansourcestenyears}{c@russiansourcestenyears}%
\@countsourceswhere{check=bibch@russiansourcesveryold}{c@russiansourcesveryold}%
\@countsourceswhere{check=bibch@foreignsourcesfiveyears}{c@foreignsourcesfiveyears}%
\@countsourceswhere{check=bibch@foreignsourcestenyears}{c@foreignsourcestenyears}%
\@countsourceswhere{check=bibch@foreignsourcesveryold}{c@foreignsourcesveryold}%
\@countsourceswhere{type=online}{c@internetsources}}

\newcommand{\@killhyperrefissue}{\renewbibmacro{pageref}{}\let\blx@anchor\relax}

\newcommand{\printannobibliography}{\begingroup\@killhyperrefissue\renewcommand*{\bibfont}{\small}\printbibliography[heading=none]\endgroup}

%% Подсчет источников различных категорий. Это следующие команды:
%%   \relatedworksourcecount   - число источников, использованных в обзоре
%%   \russiansourcesfiveyears  - число отечественных источников за последние 5 лет
%%   \russiansourcestenyears   - число отечественных источников от 5 (не включительно) до 10 лет
%%   \russiansourcesveryold    - число отечественных источников старше 10 лет
%%   \foreignsourcesfiveyears  - число иностранных источников за последние 5 лет
%%   \foreignsourcestenyears   - число иностранных источников от 5 (не включительно) до 10 лет
%%   \foreignsourcesveryold    - число иностранных источников старше 10 лет
%%   \internetsources          - число интернет-источников

%%% Сначала учимся считать источники вместо того, чтобы их печатать
\newcounter{@bibliocounter}
\defbibenvironment{@fillbibliocounter}
    {\renewcommand{\blx@driver}[1]{}}
    {}
    {\stepcounter{@bibliocounter}}

%%% Заводим счетчики под это все
\newtotcounter[auxfile=\jobname.tct]{c@relatedworksourcecount}
\newtotcounter[auxfile=\jobname.tct]{c@russiansourcesfiveyears}
\newtotcounter[auxfile=\jobname.tct]{c@russiansourcestenyears}
\newtotcounter[auxfile=\jobname.tct]{c@russiansourcesveryold}
\newtotcounter[auxfile=\jobname.tct]{c@foreignsourcesfiveyears}
\newtotcounter[auxfile=\jobname.tct]{c@foreignsourcestenyears}
\newtotcounter[auxfile=\jobname.tct]{c@foreignsourcesveryold}
\newtotcounter[auxfile=\jobname.tct]{c@internetsources}

\defbibheading{reallynone}{}

%%% Считаем в счетчик #2 число ссылок, удовлетворяющих фильтру #1
\newcommand{\@countsourceswhere}[2]{%
\setcounter{@bibliocounter}{0}%
\begingroup\@killhyperrefissue\printbibliography[env=@fillbibliocounter,heading=reallynone,#1]\endgroup%
\setcounter{#2}{\arabic{@bibliocounter}}}


%% Делаем русские варианты знаков неравенств.

\let\le\leqslant
\let\leq\leqslant
\let\ge\geqslant
\let\geq\geqslant

%% Позволяем многострочным формулам перелезать на следующие страницы.

\allowdisplaybreaks

%% Шрифты, размеры, расположения заголовков разделов.

\RequirePackage{titlesec}
\RequirePackage{titletoc}

\setcounter{secnumdepth}{3}
\titleformat{\chapter}[block]{\normalsize\bfseries\center}{\@chaptername~\thechapter.~}%
{0pt}{\begin{MakeUppercase}}[\end{MakeUppercase}\thispagestyle{\TheOnlyTruePageStyle}]
\titlespacing{\chapter}{0pt}{-30pt}{0pt}
\titleformat{\section}[block]{\normalsize\bfseries\center}{\thesection.~}{0pt}{}
\titlespacing{\section}{0pt}{0pt}{0pt}
\titleformat{\subsection}[block]{\normalsize\bfseries\center}{\thesubsection.~}{0pt}{}
\titlespacing{\subsection}{0pt}{0pt}{0pt}
\titleformat{\subsubsection}[block]{\normalsize\bfseries\center}{\thesubsubsection.~}{0pt}{}
\titlespacing{\subsubsection}{0pt}{0pt}{0pt}

%% \appendix начинает приложения, которые должны правильно именоваться.

\let\oldappendix\appendix
\renewcommand{\appendix}{
\oldappendix
%% Нумерация в приложениях идет по приложениям
\counterwithin{figure}{chapter}
\counterwithin{table}{chapter}
\counterwithin{algorithm}{chapter}
\counterwithin{lstlisting}{chapter}

\renewcommand{\thechapter}{\@appendixcounter}
\titleformat{\chapter}[block]{\normalsize\bfseries\center\stepcounter{appendix}}%
    {\@appendixname~\thechapter.~}{0pt}{\begin{MakeUppercase}}[\end{MakeUppercase}\thispagestyle{\TheOnlyTruePageStyle}]
\titlecontents{chapter}
    [\appendixPrefix]
    {}
    {\contentslabel[\@appendixname~\thecontentslabel.]{\the\appendixPrefix}}
    {\hspace*{-\the\appendixPrefix}}
    {\titlerule*[0.5pc]{.}\contentspage}
}

%% Приемлемый внешний вид содержания

\contentsmargin{1.8em}
\newcommand{\chapterW}{1.2em}
\newcommand{\sectionW}{2.2em}
\newcommand{\subsectionW}{2.6em}

\newcommand{\banhyphens}{\hyphenpenalty=10000\exhyphenpenalty=10000{}}

\AtBeginDocument{
    %% Длина "приложения" нормально определяется только теперь
    \newlength{\appendixPrefix}
    \settowidth{\appendixPrefix}{\@appendixname~M.~}
}

\newlength{\chapterPrefix}
\addtolength{\chapterPrefix}{\chapterW}

\newlength{\sectionPrefix}
\addtolength{\sectionPrefix}{\chapterPrefix}
\addtolength{\sectionPrefix}{\sectionW}

\newlength{\subsectionPrefix}
\addtolength{\subsectionPrefix}{\sectionPrefix}
\addtolength{\subsectionPrefix}{\subsectionW}

\titlecontents{chapter}
    [\chapterPrefix]
    {}
    {\contentslabel[\thecontentslabel.]{\chapterW}}
    {\hspace*{-\chapterW}}
    {\titlerule*[0.5pc]{.}\contentspage}
\titlecontents{section}
    [\sectionPrefix]
    {}
    {\contentslabel[\thecontentslabel.]{\sectionW}}
    {\hspace*{-\sectionW}}
    {\titlerule*[0.5pc]{.}\contentspage}
\titlecontents{subsection}
    [\subsectionPrefix]
    {}
    {\contentslabel[\thecontentslabel.]{\subsectionW}~}
    {\hspace*{-\subsectionW}}
    {\titlerule*[0.5pc]{.}\contentspage}

%% Выводы по главе - удобная команда

\newcommand{\chapterconclusion}{\section*{\@chapterconclusion~\thechapter}\addcontentsline{toc}{section}{\@chapterconclusion~\thechapter}}

%% ...отдельным пунктом - введение и заключение

\newcommand{\startprefacepage}{%
\chapter*{\@introductionname}\label{chapter:introduction}%
\addcontentsline{toc}{chapter}{\@introductionname}}
\newcommand{\startconclusionpage}{%
\chapter*{\@conclusionname}\label{chapter:conclusion}%
\addcontentsline{toc}{chapter}{\@conclusionname}}

%% Титульная страница

\newcommand{\hfilll}{\hspace{0pt plus 1filll}}

\RequirePackage[normalem]{ulem}

\newcommand{\uhspace}[1]{\uline{\hspace{#1}}}
\newcommand{\signatureplace}{\uhspace{7em}}
\newcommand{\datequoteplace}{\@iflfe{``\uhspace{5ex}''}{<<\uhspace{5ex}>>}}
\newcommand{\infiniteuhspace}{\uhspace{0 cm plus 1fill}}
\newcommand{\unknowndate}{\datequoteplace~\uhspace{13ex}~20\uhspace{3ex}\@iflfe{~}{~г.}}


%%% \publishyear

\newcommand{\publishyear}[1]{\newcommand{\theyear}{#1}}

\renewcommand{\maketitle}[1]{
    \pagenumbering{arabic}

    %% Ставим номер страницы снизу по центру
    \newcommand{\TheOnlyTruePageStyle}{fancy}
    \pagestyle{\TheOnlyTruePageStyle}
    \renewcommand{\headrulewidth}{0pt}
    \renewcommand{\footrulewidth}{0pt}
    \lhead{}
    \chead{}
    \rhead{}
    \lfoot{}
    \cfoot{\thepage}
    \rfoot{}
    \addtolength{\voffset}{3mm}
    \addtolength{\headsep}{-3mm}
    % Начиаем с 6 страницы
    \setcounter{page}{6}
    % Выключаем переносы в оглавлении
    \pretocmd{\tableofcontents}{\begingroup\banhyphens}{}{}
    \apptocmd{\tableofcontents}{\endgroup}{}{}
}