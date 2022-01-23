CREATE TYPE [dbo].[ColourConfig] AS TABLE(
	[Colour] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsActive] [bit] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
