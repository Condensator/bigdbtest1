CREATE TYPE [dbo].[UserPreference] AS TABLE(
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[Type] [nvarchar](15) COLLATE Latin1_General_CI_AS NOT NULL,
	[Context] [nvarchar](300) COLLATE Latin1_General_CI_AS NOT NULL,
	[PreferenceKey] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[PreferenceValue] [nvarchar](max) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[IsDefault] [bit] NOT NULL,
	[IsBookMarked] [bit] NOT NULL,
	[TransactionIdentifier] [bigint] NULL,
	[CommandPath] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[UserId] [bigint] NOT NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
