-- Portf�lio de SQL:

-- 1) Mostrando sobre todos os clientes que s�o pessoas f�sicas:
-- Primeiro e �ltimo nome
-- G�nero
-- Renda Mensal
-- Continente
SELECT
	CONCAT(FirstName, ' ', LastName) AS 'Nome_Completo',
	CASE WHEN Gender = 'F' THEN 'Mulher' ELSE 'Homem' END AS 'G�nero',
	FORMAT(YearlyIncome / 12, 'C') AS 'Renda_Mensal',
	ContinentName AS 'Continente'
FROM
	Dimcustomer
INNER JOIN DimGeography
	ON DimCustomer.GeographyKey = DimGeography.GeographyKey
WHERE CustomerType != 'Company'



-- 2) Quantidade de produtos por cor de cada marca diferente. Usando PIVOT TABLE.
-- Maneira pr�tica de coletar as diferentes cores para transform�-las em colunas.
SELECT DISTINCT QUOTENAME(TRIM(ColorName)) + ',' FROM DimProduct

-- Fazendo a PIVOT TABLE (Matriz)
SELECT * FROM (SELECT ProductName, BrandName, ColorName FROM DimProduct) AS MarcasCores
PIVOT(
	COUNT(ProductName)
	FOR ColorName
	IN(
		[Orange], [Purple], [Pink], [Green],
		[Red], [Gold], [Grey], [Transparent],
		[Black], [Silver], [Blue], [White],
		[Silver Grey], [Brown], [Yellow], [Azure]	
	)
) AS MatrizMarcasCores



-- 3) Calculando, com uma fun��o, quanto tempo o funcion�rio est�/esteve na loja e verificando se ainda est� na loja ou n�o.
-- Criando a fun��o para calcular o tempo que o funcion�rio trabalhou na loja. Caso n�o tenha sido despedido,
-- a data considerada � a do momento em que o c�digo est� sendo rodado.
GO
CREATE OR ALTER FUNCTION fnTempoTrabalho(@DataInicio AS DATE, @DataFim AS DATE)
RETURNS INT
AS
BEGIN
	DECLARE @DataTempoTrabalho INT

	IF @DataFim IS NOT NULL
		SET @DataTempoTrabalho = DATEDIFF(MONTH, @DataInicio, @DataFim)
	ELSE
		SET @DataTempoTrabalho = DATEDIFF(MONTH, @DataInicio, CAST(GETDATE() AS DATE))
	RETURN @DataTempoTrabalho
END
GO
-- Usando a fun��o e adicionando a informa��o que indica a situa��o do funcion�rio.
SELECT
	CONCAT(FirstName, ' ', LastName) AS 'Nome_Funcion�rio',
	dbo.fnTempoTrabalho(StartDate, EndDate) AS 'Qtde_Mes_Trabalho',
	CASE WHEN EndDate IS NOT NULL
		THEN 'Desligado' ELSE 'Ativo'
	END AS 'Situa��o_Funcion�rio'
FROM
	DimEmployee



-- 4) Criando uma tabela com CONSTRAINTS, 
-- inserindo valores nela,
-- testando CONSTRAINTS
-- e verificando, com uma TRANSACTION, se existem dois cliente com mesmo nome para permitir ou n�o uma mudan�a de nome.
CREATE TABLE dimClientes(
	ID_Cliente INT IDENTITY(1, 1),
	Nome_Cliente VARCHAR(MAX),
	Sexo VARCHAR(1),
	Idade INT,
	Telefone VARCHAR(9),
	CONSTRAINT dimClientes_ID_Cliente_pk PRIMARY KEY(ID_Cliente),
	CONSTRAINT dimClientes_Sexo_ck CHECK(Sexo IN ('F', 'M')),
	CONSTRAINT dimClientes_Idade_ck CHECK(Idade BETWEEN 1 AND 120),
	CONSTRAINT dimClientes_Telefone_un UNIQUE(Telefone)
)
-- Inserindo valores
INSERT INTO dimClientes(Nome_Cliente, Sexo, Idade, Telefone)
VALUES
	('Pedro',	 'M', 52, '2465-8463'),
	('Cristina', 'F', 24, '8547-2676'),
	('F�bio',	 'M', 19, '9754-1357'),
	('Beatriz',	 'F', 40, '1384-5527'),
	('Victor',   'M', 18, '1234-5678')

-- Mostrando valores da tabela
SELECT * FROM dimClientes

-- Tentando inserir algum valor n�o permitido 
INSERT INTO dimClientes(Nome_Cliente, Sexo, Idade, Telefone)
VALUES ('Victor', 'G', 18, '2345-6789') -- Sexo inv�lido
INSERT INTO dimClientes(Nome_Cliente, Sexo, Idade, Telefone)
VALUES ('Victor', 'M', 180, '2345-6789') -- Idade inv�lida
INSERT INTO dimClientes(Nome_Cliente, Sexo, Idade, Telefone)
VALUES ('Victor', 'M', 18, '1234-5678') -- Telefone igual (n�o �nico)

-- Mudando o nome de algum cliente e verificando se j� existe um cliente com o mesmo nome. Se sim, n�o permitir a mudan�a.
-- Obs: Poderia ter feito por CONSTRAINT, mas optei por verificar com uma TRANSACTION para diversifica��o no portf�lio.
BEGIN TRANSACTION T_InserirCliente
UPDATE dimClientes
SET Nome_Cliente = 'Victor'
WHERE Nome_Cliente = 'F�bio'

-- Verificando. Como j� existe outro cliente chamado Victor na tabela, o processo n�o vai ser efetuado.
DECLARE @varVerificar INT
SELECT @varVerificar = COUNT(*) FROM dimClientes WHERE Nome_Cliente = 'Victor'
IF @varVerificar > 1
	BEGIN
		ROLLBACK TRANSACTION T_InserirCliente
		PRINT 'Cliente j� existente no sistema. Processo interrompido.'
	END
ELSE
	BEGIN
		COMMIT TRANSACTION T_InserirCliente
		PRINT 'Nome mudado com sucesso!'
	END

-- Mostrando valores da tabela.
SELECT * FROM dimClientes

-- Deletando o cliente com o nome 'Victor'. Caso rodada outra vez, a TRANSACTION ser� realizada.
DELETE FROM dimClientes
WHERE Nome_Cliente = 'Victor'

-- Deletando a tabela.
DROP TABLE dimClientes



-- 5) Usando SUBQuerys para verificar os produtos das marcas que possuem mais de 200 produtos.
-- SELECT para mostrar o produto, a subcategoria, categoria e a marca das marcas que possuem mais de 200 produtos.
SELECT 
	ProductName,
	BrandName
FROM DimProduct
WHERE BrandName IN(
	-- SELECT para retornar uma lista das marcas que possuem mais de 200 produtos.
	SELECT BrandName
	FROM(
		-- SELECT para retornar tabela com todas as marcas e suas quantidades de produtos.
		SELECT BrandName, COUNT(*) AS 'QtdeProdutos'
		FROM DimProduct GROUP BY BrandName
	) AS Tabela
	WHERE QtdeProdutos > 200
)
ORDER BY BrandName