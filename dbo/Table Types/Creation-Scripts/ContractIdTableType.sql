CREATE TYPE [dbo].[ContractIdTableType] AS TABLE(
	[ContractId] [bigint] NOT NULL,
	PRIMARY KEY CLUSTERED 
(
	[ContractId] ASC
)WITH (IGNORE_DUP_KEY = OFF)
)
GO
