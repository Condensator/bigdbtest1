SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AuthorityTypes](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[SystemDefinedName] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[Category] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Entity] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Attribute] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[Expression] [nvarchar](1000) COLLATE Latin1_General_CI_AS NULL,
	[Qualfier] [nvarchar](100) COLLATE Latin1_General_CI_AS NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsActive] [bit] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
