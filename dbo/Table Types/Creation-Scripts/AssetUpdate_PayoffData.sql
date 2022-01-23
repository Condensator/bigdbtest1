CREATE TYPE [dbo].[AssetUpdate_PayoffData] AS TABLE(
	[PayoffId] [bigint] NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NOT NULL,
	[PayoffEffectiveDate] [datetime] NOT NULL,
	[SequenceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL
)
GO
