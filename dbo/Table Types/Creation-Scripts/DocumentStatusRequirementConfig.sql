CREATE TYPE [dbo].[DocumentStatusRequirementConfig] AS TABLE(
	[IsActive] [bit] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[DocumentTypeId] [bigint] NOT NULL,
	[StatusId] [bigint] NOT NULL,
	[ActionId] [bigint] NOT NULL,
	[TransactionConfigId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
