CREATE TYPE [dbo].[CPURestructure] AS TABLE(
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AtInception] [bit] NOT NULL,
	[EffectiveDate] [date] NOT NULL,
	[Status] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[CPUFinanceId] [bigint] NOT NULL,
	[CPUContractId] [bigint] NOT NULL,
	[OldCPUFinanceId] [bigint] NOT NULL,
	[ContractAmendmentReasonCodeId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
