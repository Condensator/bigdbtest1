CREATE TYPE [dbo].[ConsentConfig] AS TABLE(
	[EntityType] [nvarchar](15) COLLATE Latin1_General_CI_AS NOT NULL,
	[Id] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsMandatory] [bit] NOT NULL,
	[LegalDescription] [nvarchar](max) COLLATE Latin1_General_CI_AS NOT NULL,
	[IsActive] [bit] NOT NULL,
	[CountryId] [bigint] NOT NULL,
	[ConsentId] [bigint] NOT NULL,
	[DocumentTypeId] [bigint] NULL,
	[Token] [int] NOT NULL,
	[RowVersion] [bigint] NULL
)
GO
