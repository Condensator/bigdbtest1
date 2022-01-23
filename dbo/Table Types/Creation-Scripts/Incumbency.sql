CREATE TYPE [dbo].[Incumbency] AS TABLE(
	[IncumbencyType] [nvarchar](9) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IncumbentSigner] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ExpiryDate] [date] NULL,
	[IsActive] [bit] NOT NULL,
	[MasterAgreementId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
