CREATE TYPE [dbo].[AcceleratedBalanceDetail] AS TABLE(
	[AsofDate] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DateofDefault] [date] NULL,
	[MaturityDate] [date] NULL,
	[Status] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[CurrentLegalBalance] [bit] NOT NULL,
	[BalanceType] [nvarchar](11) COLLATE Latin1_General_CI_AS NULL,
	[Balance_Amount] [decimal](16, 2) NULL,
	[Balance_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[Number] [bigint] NOT NULL,
	[CustomerId] [bigint] NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[LegalEntityId] [bigint] NULL,
	[LineofBusinessId] [bigint] NULL,
	[JudgementId] [bigint] NULL,
	[CopyFromAcceleratedBalanceId] [bigint] NULL,
	[JobStepInstanceId] [bigint] NULL,
	[UserId] [bigint] NULL,
	[BusinessUnitId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO