CREATE TYPE [dbo].[MaturityMonitorRenewalDetail] AS TABLE(
	[RenewalTerm] [int] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RenewalFrequency] [nvarchar](13) COLLATE Latin1_General_CI_AS NULL,
	[RenewalAmount_Amount] [decimal](16, 2) NULL,
	[RenewalAmount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[RenewalDate] [date] NULL,
	[RenewalComment] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[RenewalApprovedById] [bigint] NULL,
	[ContractOptionId] [bigint] NULL,
	[MaturityMonitorId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
