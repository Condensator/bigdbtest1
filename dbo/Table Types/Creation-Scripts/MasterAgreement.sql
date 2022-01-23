CREATE TYPE [dbo].[MasterAgreement] AS TABLE(
	[Number] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AgreementAlias] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[AgreementDate] [date] NULL,
	[ReceivedDate] [date] NULL,
	[Status] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[ActivationDate] [date] NULL,
	[DeactivationDate] [date] NULL,
	[LineofBusinessId] [bigint] NULL,
	[LegalEntityId] [bigint] NULL,
	[CustomerId] [bigint] NULL,
	[AgreementTypeId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
