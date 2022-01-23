SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PartyBlackLists](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[EGNOrEIKNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[CompanyName] [nvarchar](2000) COLLATE Latin1_General_CI_AS NULL,
	[FirstName] [nvarchar](2000) COLLATE Latin1_General_CI_AS NULL,
	[LastName] [nvarchar](2000) COLLATE Latin1_General_CI_AS NULL,
	[Address] [nvarchar](2000) COLLATE Latin1_General_CI_AS NULL,
	[PhoneNumber] [nvarchar](2000) COLLATE Latin1_General_CI_AS NULL,
	[Reason] [nvarchar](2000) COLLATE Latin1_General_CI_AS NOT NULL,
	[Comment] [nvarchar](2000) COLLATE Latin1_General_CI_AS NULL,
	[IsActive] [bit] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
