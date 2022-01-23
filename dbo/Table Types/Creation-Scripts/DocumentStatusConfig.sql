CREATE TYPE [dbo].[DocumentStatusConfig] AS TABLE(
	[Name] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[SystemStatus] [nvarchar](27) COLLATE Latin1_General_CI_AS NOT NULL,
	[ApplicableForInDoc] [bit] NOT NULL,
	[ApplicableForOutDoc] [bit] NOT NULL,
	[IsMandatory] [bit] NOT NULL,
	[IsDefault] [bit] NOT NULL,
	[IsEnd] [bit] NOT NULL,
	[IsException] [bit] NOT NULL,
	[VerifyAttachment] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[SequenceNumber] [int] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
