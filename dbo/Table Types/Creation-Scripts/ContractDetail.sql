CREATE TYPE [dbo].[ContractDetail] AS TABLE(
	[ContractId] [bigint] NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[FloatRateReceivableCodeId] [bigint] NULL,
	INDEX [IX_ContractId] NONCLUSTERED 
(
	[ContractId] ASC
)
)
GO
