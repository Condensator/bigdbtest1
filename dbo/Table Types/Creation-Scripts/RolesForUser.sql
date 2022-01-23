CREATE TYPE [dbo].[RolesForUser] AS TABLE(
	[ActivationDate] [date] NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NOT NULL,
	[DeactivationDate] [date] NULL,
	[IsTemporarilyBlocked] [bit] NOT NULL,
	[RoleId] [bigint] NOT NULL,
	[UserId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
