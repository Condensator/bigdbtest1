CREATE TYPE [dbo].[CompanySocialSecurity] AS TABLE(
	[Year] [int] NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Months] [int] NULL,
	[Amount_Amount] [decimal](16, 2) NULL,
	[Amount_Currency] [nvarchar](3) COLLATE Latin1_General_CI_AS NULL,
	[NumberOfEmployees] [int] NULL,
	[TypeOfSocialSecurity] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NULL,
	[DNANoiReportId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
