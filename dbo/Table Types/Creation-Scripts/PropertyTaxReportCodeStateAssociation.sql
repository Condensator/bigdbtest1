CREATE TYPE [dbo].[PropertyTaxReportCodeStateAssociation] AS TABLE(
	[LeaseContractType] [nvarchar](16) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[LeaseTransactionType] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[StateId] [bigint] NULL,
	[PropertyTaxReportCodeConfigId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
