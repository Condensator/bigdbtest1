CREATE TYPE [dbo].[ReversalContractDetail_Extract] AS TABLE(
	[ContractId] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[LeaseUniqueId] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[ContractTypeValue] [nvarchar](14) COLLATE Latin1_General_CI_AS NULL,
	[TaxRemittanceType] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[IsSyndicated] [bit] NOT NULL,
	[JobStepInstanceId] [bigint] NOT NULL,
	[CommencementDate] [date] NULL,
	[MaturityDate] [date] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
