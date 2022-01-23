CREATE TYPE [dbo].[ConsentDetail] AS TABLE(
	[EntityType] [nvarchar](15) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[EffectiveDate] [date] NULL,
	[ExpiryDate] [date] NULL,
	[ConsentStatus] [nvarchar](8) COLLATE Latin1_General_CI_AS NOT NULL,
	[ConsentCaptureMode] [nvarchar](8) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[DocumentInstanceId] [bigint] NULL,
	[ConsentConfigId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
