\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{99_itmo-student-thesis}[2026]

% ================================================================
% БАЗОВЫЙ КЛАСС И ОБРАБОТКА ОПЦИЙ
% ================================================================
%
% Класс построен поверх extreport:
% - формат A4;
% - базовый размер шрифта 14 pt.
%
% Для обработки опций используется xkeyval/xkvltxp.
% ================================================================

\RequirePackage{xkvltxp}
\LoadClass[14pt,a4paper]{extreport}

\RequirePackage{xkeyval}

\newif\if@shouldusexelatex

% По умолчанию документ поддерживает английский и русский языки.
% Последний язык в списке считается основным языком документа.
\newcommand{\@babeloptions}{english,russian}

% Опция times:
%   включает загрузку fontspec и переключает документ на системные
%   шрифты Times New Roman / Arial / Courier New.
\DeclareOptionX{times}{\@shouldusexelatextrue}


% Пользовательский список языков.
\DeclareOptionX{languages}{\renewcommand{\@babeloptions}{#1}}

\ProcessOptionsX\relax

% ================================================================
% ШРИФТЫ И ЛОКАЛИЗАЦИЯ
% ================================================================

% Если включена опция times, ожидается сборка XeLaTeX/LuaLaTeX.
% Иначе подключается paratype как более лёгкий вариант.
\if@shouldusexelatex
    \RequirePackage{fontspec}
    \defaultfontfeatures{Ligatures={TeX},Renderer=Basic}
    \setmainfont[Ligatures={TeX,Historic}]{Times New Roman}
    \setsansfont{Arial}
    \setmonofont[Scale=MatchLowercase]{JetBrains Mono}
\else
    \RequirePackage{paratype}
\fi

% Babel отвечает за языки документа, csquotes — за корректные кавычки,
% iflang — за удобное переключение локализованных строк.
\RequirePackage[\@babeloptions]{babel}
\RequirePackage{csquotes}
\RequirePackage{iflang}

% etoolbox нужен для \pretocmd / \apptocmd,
% ifthen используется в ряде старых логических конструкций.
\RequirePackage{etoolbox}
\RequirePackage{ifthen}

% ================================================================
% ГЕОМЕТРИЯ СТРАНИЦЫ И БАЗОВАЯ ТИПОГРАФИКА
% ================================================================

% Поля страницы:
% - верхнее:   2 см
% - нижнее:    2 см
% - левое:     3 см
% - правое:    1.5 см
\RequirePackage[top=2cm, bottom=2cm, left=3cm, right=1.5cm]{geometry}

% Полуторный межстрочный интервал.
\RequirePackage{setspace}
\onehalfspacing

% Абзацный отступ.
\setlength{\parindent}{1.25cm}

% Более «плотные» списки по умолчанию.
\RequirePackage{enumitem}
\setlist{nosep}

% В маркированных списках вместо стандартного bullet используется тире.
\renewcommand\labelitemi{---}

% ================================================================
% ОСНОВНЫЕ ПАКЕТЫ ДЛЯ МАТЕМАТИКИ, ГРАФИКИ И ТАБЛИЦ
% ================================================================

% Математические пакеты.
\RequirePackage{amsmath}
\RequirePackage{amssymb}
\RequirePackage{amsthm}
\RequirePackage{amsfonts}
\RequirePackage{amsxtra}

% TikZ для схем и векторных рисунков.
\RequirePackage{tikz}
\usetikzlibrary{arrows,positioning}
\RequirePackage{adjustbox}

% Корректная работа десятичной запятой в формулах.
\RequirePackage{icomma}

% Поддержка графики и связанных элементов.
\RequirePackage{graphicx}
\RequirePackage{subcaption}
\RequirePackage{colortbl}

% Пакет для таблиц с автоматически растягиваемыми столбцами.
\RequirePackage{tabularx}

% Пакет для многостраничных таблиц.
\RequirePackage{longtable}

% ================================================================
% ЦВЕТА И РЕДАКТОРСКИЕ ПОМЕТКИ
% ================================================================

\RequirePackage{xcolor}

% Базовые цвета для листингов и внутренних пометок.
\definecolor{darkblue}{rgb}{0,0,0.5}
\definecolor{darkgreen}{rgb}{0,0.5,0}

% Простые цветные заметки внутри текста.
\newcommand{\rednote}[1]{\textcolor{red}{#1}}
\newcommand{\bluenote}[1]{\textcolor{blue}{#1}}
\newcommand{\greennote}[1]{\textcolor{green!50!black}{#1}}

% ================================================================
% ФЛОАТЫ, ПОДПИСИ И КОЛОНТИТУЛЫ
% ================================================================

% fancyhdr нужен для управления номером страницы и колонтитулами.
\RequirePackage{fancyhdr}

% Настройка подписей к рисункам, таблицам и листингам.
\RequirePackage{caption}
\RequirePackage{floatrow}

% Алгоритмы используются как общий float-контейнер для листингов,
% если это нужно в документе.
\RequirePackage{algorithm}
\RequirePackage{algorithmicx}
\RequirePackage{algpseudocode}

% Название float'а algorithm будет переопределено ниже, после
% инициализации локализованных строк.
% Команда \TheOnlyTruePageStyle объявляется заранее, чтобы ей можно
% было пользоваться и в заголовках, и в \maketitle.
\newcommand{\TheOnlyTruePageStyle}{fancy}

% ================================================================
% НУМЕРАЦИЯ СПИСКОВ И ВСПОМОГАТЕЛЬНЫЕ ЛОКАЛИЗОВАННЫЕ СТРОКИ
% ================================================================

% На первом уровне нумерованных списков в русском языке используются
% русские буквы, но без запрещённых ГОСТом букв.
\def\asbukx#1{\expandafter\@asbukx\csname c@#1\endcsname}
\def\@asbukx#1{%
    \ifcase#1\or
    а\or б\or в\or г\or д\or е\or ж\or и\or к\or л\or м\or н\or п\or р\or с\or т\or у\or ф\or х\or ц\or ш\or щ\or э\or ю\or я%
    \fi
}

\def\Asbukx#1{\expandafter\@Asbukx\csname c@#1\endcsname}
\def\@Asbukx#1{%
    \ifcase#1\or
    А\or Б\or В\or Г\or Д\or Е\or Ж\or И\or К\or Л\or М\or Н\or П\or Р\or С\or Т\or У\or Ф\or Х\or Ц\or Ш\or Щ\or Э\or Ю\or Я%
    \fi
}

\AddEnumerateCounter{\Asbukx}{\@Asbukx}{М}
\AddEnumerateCounter{\asbukx}{\@asbukx}{м}

% На втором уровне — арабские цифры с закрывающей скобкой.
\renewcommand\labelenumii{\arabic{enumii})}
\renewcommand\theenumii{\arabic{enumii}}

% Универсальная команда выбора строки по текущему основному языку:
% - первый аргумент: английская версия;
% - второй аргумент: русская версия.
\newcommand{\@iflfe}[2]{#1}

% Локализованные названия структурных элементов документа.
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

% Локализованные названия теоремоподобных окружений.
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

% Английские подписи.
\addto{\captionsenglish}{%
    \renewcommand{\@iflfe}[2]{#1}%
    \renewcommand*{\figurename}{Figure}%
    \renewcommand*{\contentsname}{Contents}%
    \renewcommand*{\labelenumi}{\alph{enumi})}%
    \renewcommand*{\theenumi}{\alph{enumi}}%
    \renewcommand*{\@tablecontinuation}[1]{Table~##1, continued}%
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

% Русские подписи.
\addto{\captionsrussian}{%
    \renewcommand{\@iflfe}[2]{#2}%
    \renewcommand*{\figurename}{Рисунок}%
    \renewcommand*{\contentsname}{Содержание}%
    \renewcommand*{\labelenumi}{\asbukx{enumi})}%
    \renewcommand*{\theenumi}{\asbukx{enumi}}%
    \renewcommand*{\@tablecontinuation}[1]{Продолжение таблицы~##1}%
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

% После объявления локализованной строки можно безопасно задать
% название algorithm-флоата.
\floatname{algorithm}{\@listingname}

% ================================================================
% МНОГОСТРАНИЧНЫЕ ТАБЛИЦЫ
% ================================================================
%
% Окружение nirtable — специализированная оболочка над longtable.
% Аргументы:
%   1 — метка;
%   2 — подпись;
%   3 — формат столбцов;
%   4 — заголовок таблицы;
%   5 — число столбцов.
% ================================================================

\newenvironment{nirtable}[5]{%
    \begin{longtable}{#3}\caption{#2}\label{#1}
    \\\hline #4 \\\hline \endfirsthead
    \multicolumn{#5}{r}{\normalsize\@tablecontinuation{\thetable}} \\\hline #4 \endhead
}{%
    \end{longtable}%
}

% ================================================================
% БИБЛИОГРАФИЯ
% ================================================================

% Основная конфигурация biblatex-gost.
\RequirePackage[
    backend=biber,
    bibencoding=utf8,
    sorting=none,
    sortcites=true,
    bibstyle=gost-numeric,
    citestyle=numeric-comp,
    autolang=other
]{biblatex}

% Заглушки под разные версии biblatex/biblatex-gost.
\providecommand{\datecircaprint}{}
\providecommand{\dateeraprintpre}[1]{}
\providecommand{\mkyearzeros}{}
\providecommand{\dateeraprint}[1]{}
\providecommand{\dateuncertainprint}{}

% Локальная подстройка библиографического оформления.
\renewbibmacro*{//}{\nopunct\printtext{\addspace\mbox{//}\addnbspace}}
\renewcommand*{\newblockpunct}{\textemdash\addnbspace\bibsentence}
\DeclareFieldFormat*{pages}{\mkpageprefix[bookpagination][\mbox]{#1}}
\DeclareFieldFormat*{labelnumberwidth}{#1}
\DefineBibliographyStrings{english}{pages={p\adddot}}
\DefineBibliographyExtras{russian}{\protected\def\bibrangedash{\textendash\penalty\hyphenpenalty}}


% Специальный драйвер для типа online.
\DeclareBibliographyDriver{online}{%
    \usebibmacro{bibindex}%
    \usebibmacro{begentry}%
    \usebibmacro{heading}%
    \newunit
    \usebibmacro{author/editor}%
    \setunit*{\labelnamepunct}%
    \usebibmacro{title}%
    \addspace\foreignlanguage{russian}{[Электронный ресурс]}%
    \setunit{\addcolondelim}%
    \usebibmacro{translation}%
    \def\bbx@gost@respdelim{\setunit{\respdelim}}%
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
    \usebibmacro{finentry}%
}

% ================================================================
% СЧЁТЧИКИ, ОБЩИЕ СЛУЖЕБНЫЕ МАКРОСЫ И БИБЛИОГРАФИЯ В ТЕКСТЕ
% ================================================================

\RequirePackage{totcount}

% Регистрируем базовые счётчики, которые могут быть полезны в документе.
\regtotcounter[auxfile=\jobname.tct]{figure}
\regtotcounter[auxfile=\jobname.tct]{table}
\regtotcounter[auxfile=\jobname.tct]{algorithm}
\newtotcounter[auxfile=\jobname.tct]{citnum}
\newtotcounter[auxfile=\jobname.tct]{appendix}

% Поле addendum в библиографии очищается для единообразного вывода.
\AtEveryBibitem{\clearfield{addendum}}

% Заголовок основного списка литературы.
\defbibheading{trueHeading}{%
    \chapter*{\@referencesname}%
    \addcontentsline{toc}{chapter}{\@referencesname}%
}

% Печать основного списка литературы.
\newcommand{\printmainbibliography}{%
    \printbibliography[heading=trueHeading]%
}

% Служебная команда для печати маленького списка публикаций без
% конфликтов с гиперссылками.
\newcommand{\@killhyperrefissue}{%
    \renewbibmacro{pageref}{}%
    \let\blx@anchor\relax%
}

\newcommand{\printannobibliography}{%
    \begingroup
    \@killhyperrefissue
    \renewcommand*{\bibfont}{\small}%
    \printbibliography[heading=none]%
    \endgroup
}

% ================================================================
% ТЕОРЕМЫ И ДОКАЗАТЕЛЬСТВА
% ================================================================

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

\renewcommand{\proof}[1][]{%
    \textit{\@proofname\ifthenelse{\equal{#1}{}}{}{ (#1)}}.~%
}

% ================================================================
% ЛИСТИНГИ ПРОГРАММНОГО КОДА
% ================================================================

\RequirePackage{listings}

% Настройка listings по умолчанию под Python.
\lstset{
    language=Python,
    extendedchars=true,
    inputencoding=utf8,
    tabsize=4,
    keywordstyle=\color{darkblue},
    commentstyle=\color{gray},
    stringstyle=\color{darkgreen},
    breaklines=true,
    showstringspaces=false,
    basicstyle=\small\ttfamily,
    keepspaces=true,
    columns=fullflexible
}

% ================================================================
% ГЛОБАЛЬНАЯ НУМЕРАЦИЯ ФЛОАТОВ И ФОРМУЛ
% ================================================================

\RequirePackage{chngcntr}

\counterwithout{figure}{chapter}
\counterwithout{table}{chapter}
\counterwithout{algorithm}{chapter}
\counterwithout{algorithm}{section}
\counterwithout{algorithm}{subsection}
\counterwithout{equation}{chapter}

\AtBeginDocument{%
    % Листинги привязываются к счётчику algorithm,
    % чтобы использовать тот же формат нумерации.
    \let\c@lstlisting\c@algorithm
    \let\thelstlisting\thealgorithm
    \let\ftype@lstlisting\ftype@algorithm
    \counterwithout{lstlisting}{chapter}
    \counterwithout{lstlisting}{section}
    \counterwithout{lstlisting}{subsection}
}

% ================================================================
% ТОНКАЯ ПОДСТРОЙКА ПЕРЕНОСОВ И ФОРМУЛ
% ================================================================

%% Вспомогательная команда для запрета переносов слов.
%% Используется, например, при выводе оглавления
%% или в названии глав, разделов и тд.
\newcommand{\banhyphens}{%
    \hyphenpenalty=10000%
    \exhyphenpenalty=10000%
}

\sloppy
\binoppenalty=10000
\relpenalty=10000
\clubpenalty=10000
\widowpenalty=10000

% Русские варианты неравенств.
\let\le\leqslant
\let\leq\leqslant
\let\ge\geqslant
\let\geq\geqslant

% Разрешаем многострочным формулам переходить на следующую страницу.
\allowdisplaybreaks

% ================================================================
% ПОДПИСИ К РИСУНКАМ, ТАБЛИЦАМ И ЛИСТИНГАМ
% ================================================================

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

% ================================================================
% ЗАГОЛОВКИ И ОГЛАВЛЕНИЕ
% ================================================================

\RequirePackage{titlesec}
\RequirePackage{titletoc}

% Нумерация до subsubsection включительно
\setcounter{secnumdepth}{3}

% Формат ненумеруемых структурных элементов:
% ВВЕДЕНИЕ, ЗАКЛЮЧЕНИЕ, СПИСОК ИСПОЛЬЗОВАННЫХ ИСТОЧНИКОВ и т.п.
\titleformat{name=\chapter,numberless}[block]
    {\normalsize\bfseries\centering}
    {}
    {0pt}
    {\banhyphens\MakeUppercase}
    [\thispagestyle{\TheOnlyTruePageStyle}]
\titlespacing*{name=\chapter,numberless}{0pt}{0pt}{12pt}

% Глава: с новой страницы, без точки после номера, без центрирования
\titleformat{\chapter}[block]
    {\normalsize\bfseries}
    {\thechapter}
    {1em}
    {\banhyphens\MakeUppercase}
    [\thispagestyle{\TheOnlyTruePageStyle}]
\titlespacing{\chapter}{\parindent}{0pt}{12pt}

% Раздел: с абзацного отступа, без точки после номера
\titleformat{\section}[block]
    {\normalsize\bfseries}
    {\thesection}
    {1em}
    {\banhyphens}
\titlespacing{\section}{\parindent}{12pt}{6pt}

% Подраздел: с абзацного отступа, без точки после номера
\titleformat{\subsection}[block]
    {\normalsize\bfseries}
    {\thesubsection}
    {1em}
    {\banhyphens}
\titlespacing{\subsection}{\parindent}{12pt}{6pt}

% Подпункт: с абзацного отступа, без точки после номера
\titleformat{\subsubsection}[block]
    {\normalsize\bfseries}
    {\thesubsubsection}
    {1em}
    {\banhyphens}
\titlespacing{\subsubsection}{\parindent}{12pt}{6pt}

% ================================================================
% ПРИЛОЖЕНИЯ
% ================================================================

\let\oldappendix\appendix
\renewcommand{\appendix}{%
    \oldappendix
    % В приложениях нумерация рисунков, таблиц, алгоритмов и листингов
    % ведётся по приложениям.
    \counterwithin{figure}{chapter}
    \counterwithin{table}{chapter}
    \counterwithin{algorithm}{chapter}
    \counterwithin{lstlisting}{chapter}

    \renewcommand{\thechapter}{\@appendixcounter}
    \titleformat{\chapter}[block]{\normalsize\bfseries\centering\stepcounter{appendix}}
        {\@appendixname~\thechapter}
        {0pt}
        {\begin{MakeUppercase}}
        [\end{MakeUppercase}\thispagestyle{\TheOnlyTruePageStyle}]

    \titlecontents{chapter}
        [\appendixPrefix]
        {}
        {\contentslabel[\@appendixname~\thecontentslabel]{\the\appendixPrefix}}
        {\hspace*{-\the\appendixPrefix}}
        {\titlerule*[0.5pc]{.}\contentspage}
}

% ================================================================
% ОГЛАВЛЕНИЕ: ВНЕШНИЙ ВИД
% ================================================================

%% Отступ между номером страницы и текстом оглавления.
\contentsmargin{1.8em}

%% Ширины блоков под номера структурных элементов в оглавлении.
%% Эти значения используются для выравнивания заголовков глав,
%% разделов и подразделов.
\newcommand{\chapterW}{1.2em}
\newcommand{\sectionW}{2.2em}
\newcommand{\subsectionW}{2.6em}

%% Ширина префикса для приложений вычисляется только после начала документа,
%% поскольку к этому моменту уже определены все локализованные подписи.
\AtBeginDocument{%
    \newlength{\appendixPrefix}%
    \settowidth{\appendixPrefix}{\@appendixname~M}%
}

%% Накопленные отступы для уровней оглавления.
\newlength{\chapterPrefix}
\setlength{\chapterPrefix}{\chapterW}

\newlength{\sectionPrefix}
\setlength{\sectionPrefix}{\chapterPrefix}
\addtolength{\sectionPrefix}{\sectionW}

\newlength{\subsectionPrefix}
\setlength{\subsectionPrefix}{\sectionPrefix}
\addtolength{\subsectionPrefix}{\subsectionW}

%% -----------------------------------------------------------------
%% Главы в оглавлении
%% -----------------------------------------------------------------
%% Для нумерованных глав выводится только номер без точки в конце.
\titlecontents{chapter}
    [\chapterPrefix]
    {}
    {\contentslabel[\thecontentslabel]{\chapterW}}
    {\hspace*{-\chapterW}}
    {\titlerule*[0.5pc]{.}\contentspage}

%% -----------------------------------------------------------------
%% Разделы в оглавлении
%% -----------------------------------------------------------------
%% Номер раздела также выводится без точки в конце.
\titlecontents{section}
    [\sectionPrefix]
    {}
    {\contentslabel[\thecontentslabel]{\sectionW}}
    {\hspace*{-\sectionW}}
    {\titlerule*[0.5pc]{.}\contentspage}

%% -----------------------------------------------------------------
%% Подразделы в оглавлении
%% -----------------------------------------------------------------
%% Номер подраздела выводится без точки в конце.
\titlecontents{subsection}
    [\subsectionPrefix]
    {}
    {\contentslabel[\thecontentslabel]{\subsectionW}\hspace{0.5em}}
    {\hspace*{-\subsectionW}}
    {\titlerule*[0.5pc]{.}\contentspage}

% ================================================================
% ВСПОМОГАТЕЛЬНЫЕ КОМАНДЫ ДЛЯ ВВЕДЕНИЯ, ЗАКЛЮЧЕНИЯ И ВЫВОДОВ
% ================================================================

\newcommand{\chapterconclusion}{%
    \section*{\@chapterconclusion~\thechapter}%
    \addcontentsline{toc}{section}{\@chapterconclusion~\thechapter}%
}

\newcommand{\startprefacepage}{%
    \chapter*{\@introductionname}\label{chapter:introduction}%
    \addcontentsline{toc}{chapter}{\@introductionname}%
    \setlength{\parindent}{1.25cm}%
    \indent%
}

\newcommand{\startconclusionpage}{%
    \chapter*{\@conclusionname}\label{chapter:conclusion}%
    \addcontentsline{toc}{chapter}{\@conclusionname}%
    \setlength{\parindent}{1.25cm}%
    \indent%
}

% ================================================================
% АВТОМАТИЧЕСКАЯ ИНИЦИАЛИЗАЦИЯ ДОКУМЕНТА
% ================================================================
%
% Титульный лист и служебные страницы формируются внешней системой,
% поэтому внутри LaTeX выполняется только техническая инициализация:
% - включается арабская нумерация страниц;
% - номер страницы ставится снизу по центру;
% - основная часть начинается с 6-й страницы;
% - в оглавлении отключаются переносы слов.
% ================================================================

\AtBeginDocument{%
    \pagenumbering{arabic}

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

    \setcounter{page}{6}

    \pretocmd{\tableofcontents}{\begingroup\banhyphens}{}{}
    \apptocmd{\tableofcontents}{\endgroup}{}{}
}