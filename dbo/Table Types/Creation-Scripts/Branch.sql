CREATE TYPE [dbo].[Branch] AS TABLE(
	[BranchNumber] [bigint] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[BranchName] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[VATRegistrationNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[BranchCode] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[CostCenter] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Status] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreationDate] [date] NOT NULL,
	[ActivationDate] [date] NULL,
	[InActivationDate] [date] NULL,
	[IsHeadquarter] [bit] NOT NULL,
	[EIKNumber_CT] [varbinary](64) NOT NULL,
	[LegalEntityId] [bigint] NOT NULL,
	[PortfolioId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
