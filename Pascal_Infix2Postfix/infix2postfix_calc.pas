program CONVERTER;

{Подключение модуля Crt}
uses crt;

{Объявление констант}
const
    INFIX_EXPR = '(1+2+3-3+1-3+5-3+3)';

{Процедура вывода на всю ширину окна горизонтальной полосы}
procedure hr;
    var
        i: integer;
    begin
        for i := 1 to 79 do write('-');
        writeln;
    end;

{Функция, возвращающая приоритет операторов/операндов.
symbol - параметр-константа типа char}
function getSymbolPriority(const symbol: char): shortint;
    begin
        case symbol of
            '(':                          getSymbolPriority := 0;
            ')':                          getSymbolPriority := 1;
            '+', '-':                     getSymbolPriority := 2;
            '*', '/':                     getSymbolPriority := 3;
            '^':                          getSymbolPriority := 4;
            'a'..'z', 'A'..'Z', '0'..'9': getSymbolPriority := 5;
        end;
    end;

{Функция, возвращающая элемент из вершины стека.
stack - параметр-константа типа string}
function getTopStack(const stack: string): char;
    begin
        getTopStack := stack[length(stack)]
    end;

{Процедура удаления элемента из вершины стека.
stack - параметр-переменная типа string}
procedure popStack(var stack: string);
    begin
        delete(stack, length(stack), 1);
    end;

{Процедура вставки элемента в вершину стека.
elem - параметр-константа типа char,
stack - параметр-переменная типа string}
procedure pushStack(const elem: char; var stack: string);
    begin
        stack := stack + elem;
    end;

{Функция, возвращающая признак пустоты стека.
stack - параметр-константа типа string}
function isEmptyStack(const stack: string): boolean;
    begin
        isEmptyStack := (length(stack) = 0);
    end;

{Функция, возвращающая выражение в обратной польской записи (постфиксной).
infix - параметр-константа типа string}
function convertToPostfix(const infix: string): string;
    var
        symbol, topStack: char;
        postfix, stack: string;
        i, j, symbolPriority, topStackPriority: shortint;
        isLte: boolean;
    begin

        {Инициализация начальных значений локальных переменных}
        symbolPriority := 0;
        topStackPriority := 0;
        postfix := '';
        stack := '';
        i := 1;

        {Организация цикла по элементам входного выражения}
        while i <= length(infix) do
            begin

                {Получение текущего символа входного выражения
                и его приоритета}
                symbol := infix[i];
                symbolPriority := getSymbolPriority(symbol);

                {Анализ приоритета текущего символа}
                if symbolPriority = 1 then

                    {Закрывающая скобка выталкивает из стека элементы
                    до ближайшей открывающей скобки включительно.
                    Вытолкнутые элементы, за исключением скобок,
                    переносятся в выходную строку.}
                    begin
                        repeat
                            topStack := getTopStack(stack);
                            popStack(stack);
                            if topStack <> '(' then
                                postfix := postfix + topStack;
                        until topStack = '(';
                        topStackPriority := symbolPriority;
                    end
                else
                    begin
                        if (symbolPriority = 0) or
                           (symbolPriority > topStackPriority) then

                            {Добавление текущего символа к вершине стека,
                            если его приоритет равен нулю (открывающая скобка)
                            или больше приоритета символа,
                            находящегося в вершине стека.}
                            begin
                                topStackPriority := symbolPriority;
                                pushStack(symbol, stack);
                            end
                        else

                            {Выталкивание из стека и перенос в выходную строку
                            элемента, находящегося в вершине стека, а также
                            следующие за ним элементы с приоритетами,
                            не меньшими приоритету текущего символа.}
                            begin
                                isLte := true;
                                repeat
                                    topStack := getTopStack(stack);
                                    topStackPriority := getSymbolPriority(topStack);
                                    if (symbolPriority > topStackPriority) or
                                       (topStack = '(') or
                                       (isEmptyStack(stack) = true) then
                                        begin
                                            pushStack(symbol, stack);
                                            topStackPriority := symbolPriority;
                                            isLte := false;
                                        end
                                    else
                                        begin
                                            popStack(stack);
                                            postfix := postfix + topStack;
                                        end;
                                until isLte = false;
                            end;
                    end;

                write(symbolPriority:3, '|':1, symbol:5, '| ':5, stack, ' | ':(17-length(stack)), postfix);
                writeln;
                i:= i + 1;
            end;

        {Выталкивание всех оставшихся в стеке символов
        и перенос их к выходной строке.}
        if isEmptyStack(stack) = false then
            for j := length(stack) downto 1 do
                begin
                    postfix := postfix + getTopStack(stack);
                    popStack(stack);
                end;
        writeln(i:3, '|':1, '|':9, '| ':18, postfix);

        convertToPostfix := postfix;
    end;

{Процедура исполнения программы}
procedure runApplication;
    var
        infixExpr, postfixExpr: string;
    begin
        clrscr; {очистка активного окна}
        infixExpr := INFIX_EXPR; {инициализация входного арифметического выражения}
        writeln('Входное выражение: ', infixExpr);
        hr;
        writeln(' № | ':5, 'Символ | ':9, 'Стек', '| ':13, 'Постфиксная строка');
        hr;
        postfixExpr := convertToPostfix(infixExpr); {преобразование}
        hr;
        writeln('Обратная польская запись (постфиксная): ', postfixExpr);
        readkey; {ожидание нажатия клавиши}
    end;

begin
    runApplication;
end.